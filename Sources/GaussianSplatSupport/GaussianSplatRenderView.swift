import CoreGraphicsSupport
import MetalKit
import MetalSupport
import RenderKit
import simd
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI

public struct GaussianSplatRenderView: View {
    private var device: MTLDevice
    private var scene: SceneGraph

    @Environment(GaussianSplatViewModel.self)
    private var viewModel

    public init(device: MTLDevice, scene: SceneGraph) {
        self.device = device
        self.scene = scene
    }

    public var body: some View {
        RenderView(device: device, passes: passes)
    }

    var passes: [any PassProtocol] {
        guard let splatsNode = scene.node(for: "splats"), let splats = splatsNode.content as? Splats<SplatC> else {
            return []
        }
        guard let cameraNode = scene.node(for: "camera"), let camera = cameraNode.camera else {
            return []
        }

        let preCalcComputePass = GaussianSplatPreCalcComputePass(
            splats: splats,
            modelMatrix: simd_float3x3(truncating: splatsNode.transform.matrix),
            cameraPosition: cameraNode.transform.translation
        )

        let gaussianSplatSortComputePass = GaussianSplatBitonicSortComputePass(
            splats: splats,
            sortRate: viewModel.sortRate
        )

        let gaussianSplatRenderPass = GaussianSplatRenderPass(
            cameraTransform: cameraNode.transform,
            cameraProjection: camera.projection,
            modelTransform: splatsNode.transform,
            splats: splats,
            debugMode: viewModel.debugMode
        )

        return [
            preCalcComputePass,
            gaussianSplatSortComputePass,
            gaussianSplatRenderPass
        ]
    }
}
