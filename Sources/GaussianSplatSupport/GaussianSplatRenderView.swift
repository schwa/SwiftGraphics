import CoreGraphicsSupport
import MetalKit
import MetalSupport
import RenderKit
import simd
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI

public struct GaussianSplatRenderView: View {
    @State
    private var device: MTLDevice

    @Environment(GaussianSplatViewModel.self)
    var viewModel

    public init(device: MTLDevice) {
        self.device = device
    }

    public var body: some View {
        RenderView(device: device, passes: passes)
    }

    var passes: [any PassProtocol] {
        let preCalcComputePass = GaussianSplatPreCalcComputePass(
            splatCount: viewModel.splats.splatBuffer.count,
            splatDistancesBuffer: Box(viewModel.splats.distances.base),
            splatBuffer: Box(viewModel.splats.splatBuffer.base),
            modelMatrix: simd_float3x3(truncating: viewModel.modelTransform.matrix),
            cameraPosition: viewModel.cameraTransform.translation
        )

        let gaussianSplatSortComputePass = GaussianSplatBitonicSortComputePass(
            splatCount: viewModel.splats.splatBuffer.count,
            splatIndicesBuffer: Box(viewModel.splats.indexBuffer.base),
            splatDistancesBuffer: Box(viewModel.splats.distances.base),
            sortRate: viewModel.sortRate
        )

        let gaussianSplatRenderPass = GaussianSplatRenderPass(
            cameraTransform: viewModel.cameraTransform,
            cameraProjection: viewModel.cameraProjection,
            modelTransform: viewModel.modelTransform,
            splatCount: viewModel.splats.splatBuffer.count,
            splats: viewModel.splats,
            debugMode: viewModel.debugMode
        )

        return [
            preCalcComputePass,
            gaussianSplatSortComputePass,
            gaussianSplatRenderPass
        ]
    }
}
