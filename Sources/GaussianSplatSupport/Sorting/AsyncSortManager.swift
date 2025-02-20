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
                try await self.startSorting()
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
    internal func requestSort(camera: simd_float4x4, model: simd_float4x4, reversed: Bool = false, count: Int) {
        Task {
            let request = SortState(camera: camera, model: model, reversed: reversed, count: count)
            await logger?.log("Sort requested: \(request.shortDescription))")
            await _sortRequestChannel.send(request)
        }
    }

    private func startSorting() async throws {
        let channel = _sortRequestChannel.removeDuplicates { lhs, rhs in
            lhs == rhs
        }
        .throttle(for: .milliseconds(33.333)) // 33.333ms = 30fps

        // swiftlint:disable:next empty_count
        for await state in channel where state.count > 0 {
            logger?.log("Sort starting: \(state.shortDescription)")
            let start = CFAbsoluteTimeGetCurrent()
            let currentIndexedDistances = try sorter.sort(splats: splatCloud.splats, camera: state.camera, model: state.model, reversed: state.reversed)
            let end = CFAbsoluteTimeGetCurrent()
            let duration = end - start
            logger?.log("Sort ended: \(state.shortDescription) (\(duration)).")
            if duration > 0.033 {
                logger?.warning("### Sort took longer than expected (\(duration), \(duration / 0.033).")
            }
            await self._sortedIndicesChannel.send(.init(state: state, indices: currentIndexedDistances))
        }
    }
}

// MARK: -

internal extension AsyncSortManager {
    static func sort(device: MTLDevice, splats: TypedMTLBuffer<Splat>, camera: simd_float4x4, model: simd_float4x4, reversed: Bool) throws -> SplatIndices {
        let sorter = CPUSplatRadixSorter<Splat>(device: device, capacity: splats.capacity)
        let indices = try sorter.sort(splats: splats, camera: camera, model: model, reversed: reversed)
        return .init(state: .init(camera: camera, model: model, reversed: reversed, count: splats.count), indices: indices)
    }
}
