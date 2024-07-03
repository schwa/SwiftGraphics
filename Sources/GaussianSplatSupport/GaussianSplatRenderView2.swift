import CoreGraphicsSupport
import MetalKit
import MetalSupport
import RenderKit
import simd
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI


public struct GaussianSplatRenderView2: View {
    @State
    private var device: MTLDevice

    @State
    private var scene: SceneGraph

    @Environment(GaussianSplatViewModel.self)
    private var viewModel

    public init(device: MTLDevice) {
        self.device = device

        let root = try! Node(label: "root") {
            Node(label: "camera").content(Camera())
            Node(label: "splats")
        }
        self.scene = SceneGraph(root: root)
    }

    public var body: some View {
        RenderView(device: device, passes: passes)
        .onChange(of: viewModel.splats) {
            scene.modify(label: "splats") {
                $0!.content = viewModel.splats
            }
        }
    }

    var passes: [any PassProtocol] {
        guard let splatsNode = scene.node(for: "splats"), let splats = splatsNode.content as? Splats<SplatC> else {
            return []
        }
        guard let cameraNode = scene.node(for: "camera"), let camera = cameraNode.camera else {
            return []
        }

        let preCalcComputePass = GaussianSplatPreCalcComputePass(
            splats: viewModel.splats,
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
