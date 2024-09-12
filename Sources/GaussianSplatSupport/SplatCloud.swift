import Algorithms
import AsyncAlgorithms
import BaseSupport
import GaussianSplatShaders
import Metal
import MetalSupport
import simd
import SIMDSupport

public protocol SplatProtocol: Equatable, Sendable {
    var floatPosition: SIMD3<Float> { get }
}

// TODO: @unchecked Sendable
public struct SplatCloud <Splat>: Equatable, @unchecked Sendable where Splat: SplatProtocol {
    public var splats: TypedMTLBuffer<Splat>
    public var indexedDistances: TypedMTLBuffer<IndexedDistance>
//    public var boundingBox: (SIMD3<Float>, SIMD3<Float>)

    public init(device: MTLDevice, capacity: Int) throws {
        self.splats = try device.makeTypedBuffer(capacity: capacity)
        self.indexedDistances = try device.makeTypedBuffer(capacity: capacity)
    }

    public init(device: MTLDevice) throws {
        try self.init(device: device, capacity: 0)
    }

    public init(device: MTLDevice, splats: TypedMTLBuffer<Splat>) throws {
        self.splats = splats

        let indexedDistances = (0 ..< splats.count).map { IndexedDistance(index: UInt32($0), distance: 0.0) }

        self.indexedDistances = try device.makeTypedBuffer(data: indexedDistances, options: .storageModeShared).labelled("Splats-IndexDistances-1") //

//        self.boundingBox = splats.withUnsafeBufferPointer { buffer in
//            let positions = buffer.map { SIMD3<Float>($0.floatPosition) }
//            // swiftlint:disable:next reduce_into
//            let minimums = positions.reduce([.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude], min)
//            // swiftlint:disable:next reduce_into
//            let maximums = positions.reduce([-.greatestFiniteMagnitude, -.greatestFiniteMagnitude, -.greatestFiniteMagnitude], max)
//            return (minimums, maximums)
//        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.splats == rhs.splats
            && lhs.indexedDistances == rhs.indexedDistances
    }

    public var count: Int {
        assert(splats.count == indexedDistances.count)
        return splats.count
    }
}

public extension SplatCloud {
    init(device: MTLDevice, splats: [Splat]) throws {
        let typedMTLBuffer = try device.makeTypedBuffer(data: splats)
        try self.init(device: device, splats: typedMTLBuffer)
    }
}

public extension SplatCloud {
    mutating func append(splats: [Splat]) throws {
        let count = count
        try self.splats.append(contentsOf: splats)
        try self.indexedDistances.append(contentsOf: (0 ..< splats.count).map { IndexedDistance(index: UInt32(count + $0), distance: 0.0) })
    }
}

extension SplatCloud: CustomDebugStringConvertible {
    public var debugDescription: String {
        "SplatCloud<\(type(of: Splat.self))>(splats: \(splats), indexedDistances: \(indexedDistances))"
    }
}

//public extension SplatCloud {
//    func center() -> SIMD3<Float> {
//        (boundingBox.0 + boundingBox.1) / 2
//    }
//}

// MARK: -

public struct SplatB: Equatable, Sendable {
    public var position: PackedFloat3
    public var scale: PackedFloat3
    public var color: SIMD4<UInt8>
    public var rotation: SIMD4<UInt8>

    public init(position: PackedFloat3, scale: PackedFloat3, color: SIMD4<UInt8>, rotation: SIMD4<UInt8>) {
        self.position = position
        self.scale = scale
        self.color = color
        self.rotation = rotation
    }
}

// Metal Debugger: half3 position, half4 color, half3 cov_a, half3 cov_b
public struct SplatC: Equatable, Sendable {
    public var position: PackedHalf3
    public var color: PackedHalf4
    public var cov_a: PackedHalf3
    public var cov_b: PackedHalf3

    public init(position: PackedHalf3, color: PackedHalf4, cov_a: PackedHalf3, cov_b: PackedHalf3) {
        self.position = position
        self.color = color
        self.cov_a = cov_a
        self.cov_b = cov_b
    }
}

extension SplatC: SplatProtocol {
    public var floatPosition: SIMD3<Float> {
        .init(position)
    }
}

// MARK: -

public extension SplatCloud where Splat == SplatC {
    init(device: MTLDevice, url: URL, splatLimit: Int? = nil) throws {
        let data = try Data(contentsOf: url)
        let splats: TypedMTLBuffer<SplatC>
        if url.pathExtension == "splat" {
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
            splats = try device.makeTypedBuffer(data: splatArray, options: .storageModeShared).labelled("Splats")
        } else {
            throw BaseError.error(.illegalValue)
        }
        try self.init(device: device, splats: splats)
    }
}
