import BaseSupport
import Metal
import RenderKit
import simd

struct GaussianSplatCompositePass: GroupPassProtocol {
    var id: AnyHashable
    var scene: SceneGraph
    var sortRate: Int

    func children() throws -> [any PassProtocol] {
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
            sortRate: sortRate
        )
        let gaussianSplatRenderPass = GaussianSplatRenderPass(
            scene: scene,
            debugMode: false
        )
        return [
            preCalcComputePass,
            gaussianSplatSortComputePass,
            gaussianSplatRenderPass
        ]
    }
}
