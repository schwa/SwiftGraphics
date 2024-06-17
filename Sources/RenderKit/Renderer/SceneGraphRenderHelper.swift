import simd

public struct SceneGraphRenderHelper {
    public struct Element <Material> {
        public var node: Node
        public var material: Material?
        public var geometry: Geometry
        // TODO: Some of these should be calculated on the fly.
        public var modelMatrix: simd_float4x4
        public var modelViewMatrix: simd_float4x4
        public var modelViewProjectionMatrix: simd_float4x4
        public var modelNormalMatrix: simd_float3x3
    }

    public var scene: SceneGraph
    public var drawableSize: SIMD2<Float>
    public var viewMatrix: simd_float4x4
    public var projectionMatrix: simd_float4x4

    public init(scene: SceneGraph, drawableSize: SIMD2<Float>) throws {
        // TODO: Throw
        assert(drawableSize.x > 0 && drawableSize.y > 0)
        self.scene = scene
        self.drawableSize = drawableSize

        guard let currentCameraNode = scene.currentCameraNode else {
            fatalError() // TODO: Throw
        }
        viewMatrix = currentCameraNode.transform.matrix.inverse
        projectionMatrix = currentCameraNode.content!.camera!.projectionMatrix(for: drawableSize)
    }

    public func elements() throws -> any Sequence<Element<()>> {
        // TODO: concat node's transform with parent node's transforms

        scene.root.allNodes().compactMap { node in
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

    public func elements <Material>(material: Material.Type) -> any Sequence<Element<Material>> where Material: MaterialProtocol {
        // TODO: concat node's transform with parent node's transforms
        scene.root.allNodes().compactMap { node in
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
