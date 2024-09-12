import Algorithms
import AsyncAlgorithms
import BaseSupport
import GaussianSplatShaders
import Metal
import MetalSupport
import simd
import SIMDSupport

// TODO: @unchecked Sendable
public final class SplatCloud <Splat>: Equatable, @unchecked Sendable where Splat: SplatProtocol {
    public var splats: TypedMTLBuffer<Splat>
    public var indexedDistances: TupleBuffered<TypedMTLBuffer<IndexedDistance>>
    public var temporaryIndexedDistances: [IndexedDistance]
    //    public var boundingBox: (SIMD3<Float>, SIMD3<Float>)

    public init(device: MTLDevice, capacity: Int) throws {
        self.splats = try device.makeTypedBuffer(capacity: capacity)
        self.indexedDistances = .init(keys: ["onscreen", "offscreen"], elements: [
            try device.makeTypedBuffer(capacity: capacity).labelled("Splats-IndexDistances-1"),
            try device.makeTypedBuffer(capacity: capacity).labelled("Splats-IndexDistances-2"),
        ])
        self.temporaryIndexedDistances = []
    }

    public convenience init(device: MTLDevice) throws {
        try self.init(device: device, capacity: 0)
    }

    public init(device: MTLDevice, splats: TypedMTLBuffer<Splat>) throws {
        self.splats = splats

        let indexedDistances = (0 ..< splats.count).map { IndexedDistance(index: UInt32($0), distance: 0.0) }
        self.indexedDistances = .init(keys: ["onscreen", "offscreen"], elements: [
            try device.makeTypedBuffer(data: indexedDistances, options: .storageModeShared).labelled("Splats-IndexDistances-1"),
            try device.makeTypedBuffer(data: indexedDistances, options: .storageModeShared).labelled("Splats-IndexDistances-2"),
        ])
        temporaryIndexedDistances = Array(repeating: .init(index: 0, distance: 0), count: splats.count)
    }

    public static func == (lhs: SplatCloud, rhs: SplatCloud) -> Bool {
        lhs.splats == rhs.splats
        && lhs.indexedDistances == rhs.indexedDistances
    }

    public var count: Int {
        assert(splats.count == indexedDistances.onscreen.count)
        assert(splats.count == indexedDistances.offscreen.count)
        return splats.count
    }
}

public extension SplatCloud {
    convenience init(device: MTLDevice, splats: [Splat]) throws {
        let typedMTLBuffer = try device.makeTypedBuffer(data: splats)
        try self.init(device: device, splats: typedMTLBuffer)
    }
}

public extension SplatCloud {
    func append(splats: [Splat]) throws {
        let originalCount = count
        try self.splats.append(contentsOf: splats)
        try self.indexedDistances.onscreen.append(contentsOf: (0 ..< splats.count).map { IndexedDistance(index: UInt32(originalCount + $0), distance: 0.0) })
        try self.indexedDistances.offscreen.append(contentsOf: (0 ..< splats.count).map { IndexedDistance(index: UInt32(originalCount + $0), distance: 0.0) })
        self.temporaryIndexedDistances += Array(repeating: .init(index: 0, distance: 0), count: splats.count)
    }
}

extension SplatCloud: CustomDebugStringConvertible {
    public var debugDescription: String {
        "SplatCloud<\(type(of: Splat.self))>(splats: \(splats), indexedDistances: \(indexedDistances))"
    }
}

// MARK: -

public extension SplatCloud where Splat == SplatC {
    convenience init(device: MTLDevice, data: Data, splatLimit: Int? = nil) throws {
        let splatArray = data.withUnsafeBytes { buffer in
            buffer.withMemoryRebound(to: SplatB.self) { splats in
                // NOTE: This is horrendously expensive.
                if let splatLimit, splatLimit < splats.count {
                    print("TODO: Sorting splats in CPU.") // TODO: FIXME - replace with radix sort.
                    let positions = splats.map { SIMD3<Float>($0.position) }
                    // swiftlint:disable:next reduce_into
                    let minimums = positions.reduce([.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude], min)
                    // swiftlint:disable:next reduce_into
                    let maximums = positions.reduce([-.greatestFiniteMagnitude, -.greatestFiniteMagnitude, -.greatestFiniteMagnitude], max)
                    let center = (minimums + maximums) * 0.5
                    let splats = splats.sorted { lhs, rhs in
                        let lhs = SIMD3<Float>(lhs.position).distance(to: center)
                        let rhs = SIMD3<Float>(rhs.position).distance(to: center)
                        return lhs < rhs
                    }
                    return convert_b_to_c(splats.prefix(splatLimit))
                }
                else {
                    return convert_b_to_c(splats)
                }
            }
        }
        let splats = try device.makeTypedBuffer(data: splatArray, options: .storageModeShared).labelled("Splats")
        try self.init(device: device, splats: splats)
    }

    convenience init(device: MTLDevice, url: URL, splatLimit: Int? = nil) throws {
        let data = try Data(contentsOf: url)
        let splats: TypedMTLBuffer<SplatC>
        if url.pathExtension == "splat" {
            try self.init(device: device, data: data)
        } else {
            throw BaseError.error(.illegalValue)
        }
    }
}

extension SplatCloud {
    // TODO: Should add in model transform for splat cloud too.
    func sortIndices(camera: simd_float4x4) {
        guard indexedDistances.offscreen.count > 1 else {
            return
        }
        indexedDistances.offscreen.withUnsafeMutableBufferPointer { indexedDistances in
            // Compute distances.

            var minDistance: Float = .greatestFiniteMagnitude
            var maxDistance: Float = -.greatestFiniteMagnitude

            timeit("CalcDistance") {
                splats.withUnsafeBufferPointer { splats in
                    for index in 0..<indexedDistances.count {
                        let distance = splats[index].floatPosition.distance(to: camera.translation)
                        indexedDistances[index] = .init(index: UInt32(index), distance: distance)
                        minDistance = min(minDistance, distance)
                        maxDistance = max(maxDistance, distance)
                    }
                }
            }

            // Sort
            timeit("Sort") {
                temporaryIndexedDistances.withUnsafeMutableBufferPointer { temporaryIndexedDistances in
                    RadixSortCPU<IndexedDistance>().radixSort(input: indexedDistances, temp: temporaryIndexedDistances)
                }
            }
        }
    }
}

extension IndexedDistance: RadixSortable {
//    var key: UInt32 {
//        // TODO: this is a total hack that doesn't take min/max range into account.
//        UInt32.max - UInt32(distance * 1_000_000 + 1_000_000)
//    }

    func key(shift: Int) -> Int {
        fatalError()
    }
}
