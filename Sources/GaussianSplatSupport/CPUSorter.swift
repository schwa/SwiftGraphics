import AsyncAlgorithms
import BaseSupport
import GaussianSplatShaders
@preconcurrency import Metal
import MetalSupport
import os
import simd
import SIMDSupport

internal actor CPUSorter <Splat> where Splat: SplatProtocol {
    internal static func sort(device: MTLDevice, splats: TypedMTLBuffer<Splat>, camera: simd_float4x4, model: simd_float4x4) throws -> SplatIndices {
        var indexedDistances = try device.makeTypedBuffer(data: [IndexedDistance](repeating: .init(), count: splats.count)).labelled("Splats-IndexDistances-0")
        var temporaryIndexedDistances = [IndexedDistance](repeating: .init(), count: splats.count)
        sort(splats: splats, indexedDistances: &indexedDistances, temporaryIndexedDistances: &temporaryIndexedDistances, camera: camera, model: model)
        return .init(state: .init(camera: camera, model: model, count: splats.count), indices: indexedDistances)
    }

    private static func sort(splats: TypedMTLBuffer<Splat>, indexedDistances: inout TypedMTLBuffer<IndexedDistance>, temporaryIndexedDistances: inout [IndexedDistance], camera: simd_float4x4, model: simd_float4x4) {
        guard splats.count > 1 else {
            return
        }
        let start = getMachTime()
        releaseAssert(splats.count <= indexedDistances.capacity, "Too few indexed distances \(indexedDistances.count) for \(splats.capacity) splats.")
        releaseAssert(splats.count <= temporaryIndexedDistances.count, "Too few temporary indexed distances \(temporaryIndexedDistances.count) for \(splats.count) splats.")
        indexedDistances.withUnsafeMutableBufferPointer { indexedDistances in
            let indexedDistances = UnsafeMutableBufferPointer<IndexedDistance>(start: indexedDistances.baseAddress, count: splats.count)
            // Compute distances.
            let modelView = camera.inverse * model
            releaseAssert(splats.count <= indexedDistances.count, "Cannot sort \(splats.count) splats into \(indexedDistances.count) indexed distances.")
            splats.withUnsafeBufferPointer { splats in
                for index in 0..<splats.count {
                    let position = modelView * SIMD4<Float>(splats[index].floatPosition, 1.0)
                    let distance = position.z
                    indexedDistances[index] = .init(index: UInt32(index), distance: distance)
                }
            }
            temporaryIndexedDistances.withUnsafeMutableBufferPointer { temporaryIndexedDistances in
                let temporaryIndexedDistances = UnsafeMutableBufferPointer<IndexedDistance>(start: temporaryIndexedDistances.baseAddress, count: splats.count)
                releaseAssert(splats.count == indexedDistances.count, "Mismatch between splats \(splats.count) and indexed distances \(indexedDistances.count).")
                releaseAssert(splats.count == temporaryIndexedDistances.count, "Mismatch between splats \(splats.count) and temporary indexed distances \(temporaryIndexedDistances.count).")
                releaseAssert(temporaryIndexedDistances.count == indexedDistances.count, "Mismatch between temporary indexed distances \(temporaryIndexedDistances.count) and indexed distances \(indexedDistances.count).")
                RadixSortCPU<IndexedDistance>().radixSort(input: indexedDistances, temp: temporaryIndexedDistances)
            }
        }
        indexedDistances.count = splats.count
        let end = getMachTime()
//        print("XYZZY: \(Measurement(value: end - start, unit: UnitDuration.seconds).converted(to: UnitDuration.milliseconds))")
    }

    private var device: MTLDevice
    private var splatCloud: SplatCloud<Splat>
    private var temporaryIndexedDistances: [IndexedDistance]
    private var _sortRequestChannel: AsyncChannel<SortState> = .init()
    private var _sortedIndicesChannel: AsyncChannel<SplatIndices> = .init()
    private var capacity: Int
    private var logger: Logger? = Logger()

    internal init(device: MTLDevice, splatCloud: SplatCloud<Splat>, capacity: Int) throws {
        self.device = device
        self.capacity = capacity
        print("\(splatCloud.capacity) / \(capacity)")
        releaseAssert(capacity > 0, "You shouldn't be creating a CPUSorter with a capacity of zero.")
        self.splatCloud = splatCloud
        temporaryIndexedDistances = .init(repeating: .init(), count: capacity)
        Task(priority: .high) {
            do {
                try await self.sort()
            }
            catch is CancellationError {
            }
            catch {
                await logger?.log("Failed to sort splats: \(error)")
            }
        }
    }

    internal func sortedIndicesChannel() -> AsyncChannel<SplatIndices> {
        _sortedIndicesChannel
    }

    nonisolated
    func requestSort(camera: simd_float4x4, model: simd_float4x4, count: Int) {
        Task {
            await _sortRequestChannel.send(.init(camera: camera, model: model, count: count))
        }
    }

    private func sort() async throws {
        let device = device
        let capacity = capacity
        let counter = OSAllocatedUnfairLock(initialState: 0)
        // swiftlint:disable:next empty_count
        for await state in _sortRequestChannel.removeDuplicates() where state.count > 0 {
            var temporaryIndexedDistances = temporaryIndexedDistances
            var currentIndexedDistances = try device.makeTypedBuffer(element: IndexedDistance.self, capacity: capacity).labelled("Splats-IndexDistances-\(counter.postIncrement())")
            Self.sort(splats: splatCloud.splats, indexedDistances: &currentIndexedDistances, temporaryIndexedDistances: &temporaryIndexedDistances, camera: state.camera, model: state.model)
            await self._sortedIndicesChannel.send(.init(state: state, indices: currentIndexedDistances))
        }
    }
}

extension OSAllocatedUnfairLock where State == Int {
    func postIncrement() -> State {
        withLock { state in
            defer {
                state += 1
            }
            return state
        }
    }
}

// MARK: -

extension IndexedDistance: RadixSortable {
    func key(shift: Int) -> Int {
        let bits = distance.bitPattern
        let signMask: UInt32 = 0x80000000
        let key: UInt32 = (bits & signMask != 0) ? ~bits : bits ^ signMask
        return (Int(key) >> shift) & 0xFF
    }
}

// MARK: -

extension IndexedDistance: @unchecked @retroactive Sendable {
}

// MARK: -
