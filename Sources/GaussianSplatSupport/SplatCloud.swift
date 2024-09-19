import AsyncAlgorithms
import BaseSupport
import GaussianSplatShaders
import os
import Metal
import MetalSupport
import simd
import SIMDSupport

// TODO: @unchecked Sendable
public final class SplatCloud <Splat>: Equatable, @unchecked Sendable where Splat: SplatProtocol {
    public private(set) var splats: TypedMTLBuffer<Splat>
    internal var indexedDistances: TupleBuffered<TypedMTLBuffer<IndexedDistance>>
    internal let temporaryIndexedDistancePool: Pool<[IndexedDistance]> = .init()

    public init(device: MTLDevice, capacity: Int) throws {
        self.splats = try device.makeTypedBuffer(capacity: capacity)
        self.indexedDistances = .init(keys: ["onscreen", "offscreen"], elements: [
            try device.makeTypedBuffer(capacity: capacity).labelled("Splats-IndexDistances-1"),
            try device.makeTypedBuffer(capacity: capacity).labelled("Splats-IndexDistances-2"),
        ])
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
    }

    public static func == (lhs: SplatCloud, rhs: SplatCloud) -> Bool {
        lhs === rhs
    }

    public var count: Int {
        assert(splats.count == indexedDistances.onscreen.count)
        assert(splats.count == indexedDistances.offscreen.count)
        return splats.count
    }

    public var onscreenIndexedDistances: TypedMTLBuffer<IndexedDistance> {
        return indexedDistances.onscreen
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
        if url.pathExtension == "splat" {
            try self.init(device: device, data: data)
        } else {
            throw BaseError.error(.illegalValue)
        }
    }
}

extension SplatCloud {
    func sortIndices(camera: simd_float4x4, model: simd_float4x4) {
        guard indexedDistances.offscreen.count > 1 else {
            return
        }
        indexedDistances.offscreen.withUnsafeMutableBufferPointer { indexedDistances in
            // Compute distances.
            let modelView = camera.inverse * model
            splats.withUnsafeBufferPointer { splats in
                for index in 0..<indexedDistances.count {
                    let position = modelView * SIMD4<Float>(splats[index].floatPosition, 1.0)
                    let distance = position.z
                    indexedDistances[index] = .init(index: UInt32(index), distance: distance)
                }
            }

            //
            temporaryIndexedDistancePool.withMutableElement(default: Array(repeating: IndexedDistance(), count: splats.count)) { temporaryIndexedDistances in
                temporaryIndexedDistances.withUnsafeMutableBufferPointer { temporaryIndexedDistances in
                    RadixSortCPU<IndexedDistance>().radixSort(input: indexedDistances, temp: temporaryIndexedDistances)
                }
            }
        }
    }
}

extension IndexedDistance: RadixSortable {
    func key(shift: Int) -> Int {
        let bits = distance.bitPattern
        let signMask: UInt32 = 0x80000000
        let key: UInt32 = (bits & signMask != 0) ? ~bits : bits ^ signMask
        return (Int(key) >> shift) & 0xFF
    }
}

struct SortDataKey: Sendable {
    var date: Date
    var camera: simd_float4x4
    var model: simd_float4x4
    var count: Int
    var sorted: Bool
}

extension SortDataKey: Equatable {
}

extension SortDataKey: Hashable {
    func hash(into hasher: inout Hasher) {
        date.hash(into: &hasher)
        camera.scalars.hash(into: &hasher)
        model.scalars.hash(into: &hasher)
        count.hash(into: &hasher)
        sorted.hash(into: &hasher)
    }
}

final class Pool <T>: Sendable where T: Sendable {
    let elements: OSAllocatedUnfairLock<[T]> = .init(initialState: [])
    let highWaterCount: OSAllocatedUnfairLock = .init(initialState: 0)
    let logger: Logger? = .init()

    init() {
    }

    private func push(element: T) {
        elements.withLock { elements in
            elements.append(element)
            let count = elements.count
            let highWaterCount: Int? = self.highWaterCount.withLock { highWaterCount in
                if count > highWaterCount {
                    highWaterCount = count
                    return highWaterCount
                }
                return nil
            }
            if let highWaterCount {
                logger?.log("High water mark: \(highWaterCount)")
            }

        }
    }

    private func pop(default: @Sendable () -> T) -> T {
        elements.withLock { elements in
            elements.popLast() ?? `default`()

        }
    }

    func withElement <R>(default: @autoclosure @Sendable () -> T, _ closure: (T) throws -> R) rethrows -> R {
        let element = pop(default: `default`)
        defer {
            push(element: element)
        }
        return try closure(element)
    }

    func withMutableElement <R>(default: @autoclosure @Sendable () -> T, _ closure: (inout T) throws -> R) rethrows -> R {
        var element = pop(default: `default`)
        defer {
            push(element: element)
        }
        return try closure(&element)
    }
}

extension IndexedDistance: @unchecked @retroactive Sendable {
}
