import BaseSupport
import CoreGraphicsSupport
import MetalKit
import MetalSupport
import RenderKit
import simd
import SIMDSupport
import SwiftUI

@Observable
public class GaussianSplatViewModel {
    public var debugMode: Bool
    public var sortRate: Int

    public init(debugMode: Bool = false, sortRate: Int = 1) {
        self.debugMode = debugMode
        self.sortRate = sortRate
    }
}

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
            .toolbar {
                // TODO: this should not be here.
                Button("Screenshot") {
                    screenshot()
                }
            }
    }

    var passes: [any PassProtocol] {
        guard let splatsNode = scene.node(for: "splats"), let splats = splatsNode.content as? Splats else {
            return []
        }
        guard let cameraNode = scene.node(for: "camera") else {
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
        //        let gaussianSplatRenderPass = GaussianSplatRenderPass(
        //            scene: scene,
        //            debugMode: viewModel.debugMode
        //        )
        let gaussianSplatRenderPass = GaussianSplatRenderPass(
            scene: scene,
            debugMode: false)
        return [
            preCalcComputePass,
            gaussianSplatSortComputePass,
            gaussianSplatRenderPass
        ]
    }

    func screenshot() {
        do {
            var offscreenRenderer = try OffscreenRenderer(device: device, size: CGSize(width: 1600, height: 1200), passes: passes)
            try offscreenRenderer.configure()
            try offscreenRenderer.render()
            guard let targetTexture = offscreenRenderer.targetTexture else {
                fatalError()
            }
            guard let cgImage = targetTexture.cgImage() else {
                fatalError()
            }
            let url = URL(filePath: "/tmp/test.png")
            try cgImage.write(to: url)
            url.reveal()
        }
        catch {
            print(error)
        }
    }
}
