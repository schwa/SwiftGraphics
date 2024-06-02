import simd

struct SceneGraphRenderHelper {
    struct Element <Material> {
        var node: Node
        var material: Material?
        var geometry: Geometry
        // TODO: Some of these should be calculated on the fly.
        var modelMatrix: simd_float4x4
        var modelViewMatrix: simd_float4x4
        var modelViewProjectionMatrix: simd_float4x4
        var modelNormalMatrix: simd_float3x3
    }

    var scene: SceneGraph
    var drawableSize: SIMD2<Float>
    var viewMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4


    init(scene: SceneGraph, drawableSize: SIMD2<Float>) throws {
        // TODO: Throw
        assert(drawableSize.x > 0 && drawableSize.y > 0)
        self.scene = scene
        self.drawableSize = drawableSize

        guard let currentCameraNode = scene.currentCameraNode else {
            fatalError() // TODO: Throw
        }
        viewMatrix = currentCameraNode.transform.matrix.inverse
        projectionMatrix = currentCameraNode.content!.camera!.projectionMatrix(aspectRatio: drawableSize.x / drawableSize.y)
    }

    func elements() throws -> any Sequence<Element<()>> {

        // TODO: concat node's transform with parent node's transforms

        return scene.root.allNodes().compactMap { node in
            guard let geometry = node.content?.geometry else {
                return nil
            }
            // TODO: Move this all into element.
            let modelMatrix = node.transform.matrix
            let modelViewMatrix = viewMatrix * modelMatrix
            let modelViewProjectionMatrix = projectionMatrix * viewMatrix * modelMatrix
            let modelNormalMatrix = simd_float3x3(truncating: node.transform.matrix).inverse

            return Element<()>(node: node, material: nil, geometry: geometry, modelMatrix: modelMatrix, modelViewMatrix: modelViewMatrix, modelViewProjectionMatrix: modelViewProjectionMatrix, modelNormalMatrix: modelNormalMatrix)
        }
        .lazy
    }

    func elements <Material>(material: Material.Type) -> any Sequence<Element<Material>> where Material: SG3MaterialProtocol {
        // TODO: concat node's transform with parent node's transforms
        return scene.root.allNodes().compactMap { node in
            guard let geometry = node.content?.geometry else {
                return nil
            }
            // TODO: Only doing first material
            guard let material = geometry.materials[0] as? Material else {
                return nil
            }

            // TODO: Move this all into element.
            let modelMatrix = node.transform.matrix
            let modelViewMatrix = viewMatrix * modelMatrix
            let modelViewProjectionMatrix = projectionMatrix * viewMatrix * modelMatrix
            let modelNormalMatrix = simd_float3x3(truncating: node.transform.matrix).inverse

            return Element<Material>(node: node, material: material, geometry: geometry, modelMatrix: modelMatrix, modelViewMatrix: modelViewMatrix, modelViewProjectionMatrix: modelViewProjectionMatrix, modelNormalMatrix: modelNormalMatrix)
        }
        .lazy
    }
}
