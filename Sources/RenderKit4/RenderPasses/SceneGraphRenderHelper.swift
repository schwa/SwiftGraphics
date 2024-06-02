import simd

struct SceneGraphRenderHelper {
    var scene: SceneGraph
    var viewMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4

    struct Element <Material> {
        var node: Node
        var material: Material
        var geometry: Geometry
        // TODO: Some of these should be calculated on the fly.
        var modelMatrix: simd_float4x4
        var modelViewMatrix: simd_float4x4
        var modelViewProjectionMatrix: simd_float4x4
        var modelNormalMatrix: simd_float3x3
    }

    init(scene: SceneGraph, drawableSize: SIMD2<Float>) {
        assert(drawableSize.x > 0 && drawableSize.y > 0)

        self.scene = scene
        guard let currentCameraNode = scene.currentCameraNode else {
            fatalError()
        }

        viewMatrix = currentCameraNode.transform.matrix.inverse
        projectionMatrix = currentCameraNode.content!.camera!.projectionMatrix(aspectRatio: drawableSize.x / drawableSize.y)
    }

    func elements() -> any Sequence<Element<()>> {
        scene.root.allNodes().compactMap { node in
            guard let geometry = node.content?.geometry else {
                return nil
            }
            let modelMatrix = node.transform.matrix
            let modelViewMatrix = viewMatrix * modelMatrix
            let modelViewProjectionMatrix = projectionMatrix * viewMatrix * modelMatrix
            let modelNormalMatrix = simd_float3x3(truncating: node.transform.matrix).inverse

            return Element<()>(node: node, material: (), geometry: geometry, modelMatrix: modelMatrix, modelViewMatrix: modelViewMatrix, modelViewProjectionMatrix: modelViewProjectionMatrix, modelNormalMatrix: modelNormalMatrix)
        }
        .lazy
    }

    func elements <Material>(material: Material.Type) -> any Sequence<Element<Material>> where Material: SG3MaterialProtocol {
        scene.root.allNodes().compactMap { node in
            guard let geometry = node.content?.geometry else {
                return nil
            }
            // TODO: Only doing first material
            guard let material = geometry.materials[0] as? Material else {
                return nil
            }

            let modelMatrix = node.transform.matrix
            let modelViewMatrix = viewMatrix * modelMatrix
            let modelViewProjectionMatrix = projectionMatrix * viewMatrix * modelMatrix
            let modelNormalMatrix = simd_float3x3(truncating: node.transform.matrix).inverse

            return Element<Material>(node: node, material: material, geometry: geometry, modelMatrix: modelMatrix, modelViewMatrix: modelViewMatrix, modelViewProjectionMatrix: modelViewProjectionMatrix, modelNormalMatrix: modelNormalMatrix)

        }
        .lazy
    }
}
