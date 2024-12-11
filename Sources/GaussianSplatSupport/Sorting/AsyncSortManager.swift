import AsyncAlgorithms
import BaseSupport
import GaussianSplatShaders
@preconcurrency import Metal
import MetalSupport
import os
import simd
import SIMDSupport

internal actor AsyncSortManager <Splat> where Splat: SplatProtocol {
    private var splatCloud: SplatCloud<Splat>
    private var _sortRequestChannel: AsyncChannel<SortState> = .init()
    private var _sortedIndicesChannel: AsyncChannel<SplatIndices> = .init()
    private var logger: Logger?
    private var sorter: CPUSplatRadixSorter<Splat>

    internal init(device: MTLDevice, splatCloud: SplatCloud<Splat>, capacity: Int, logger: Logger? = nil) throws {
        self.sorter = .init(device: device, capacity: capacity)
        self.splatCloud = splatCloud
        self.logger = logger
        Task(priority: .high) {
            do {
                try await self.sort()
            }
            catch is CancellationError {
                // This line intentionally left blank.
            }
            catch {
                logger?.log("Failed to sort splats: \(error)")
            }
        }
    }

    internal func sortedIndicesChannel() -> AsyncChannel<SplatIndices> {
        _sortedIndicesChannel
    }

    nonisolated
    internal func requestSort(camera: simd_float4x4, model: simd_float4x4, count: Int) {
        Task {
            await _sortRequestChannel.send(.init(camera: camera, model: model, count: count))
        }
    }

    internal func sort() async throws {
        // swiftlint:disable:next empty_count
        for await state in _sortRequestChannel.removeDuplicates() where state.count > 0 {
            let currentIndexedDistances = try sorter.sort(splats: splatCloud.splats, camera: state.camera, model: state.model)
            await self._sortedIndicesChannel.send(.init(state: state, indices: currentIndexedDistances))
        }
    }
}

// MARK: -

internal extension AsyncSortManager {
    static func sort(device: MTLDevice, splats: TypedMTLBuffer<Splat>, camera: simd_float4x4, model: simd_float4x4) throws -> SplatIndices {
        let sorter = CPUSplatRadixSorter<Splat>(device: device, capacity: splats.capacity)
        let indices = try sorter.sort(splats: splats, camera: camera, model: model)
        return .init(state: .init(camera: camera, model: model, count: splats.count), indices: indices)
    }
}
