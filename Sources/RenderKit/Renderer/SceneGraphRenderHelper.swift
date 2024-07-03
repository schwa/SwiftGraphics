import simd

public struct SceneGraphRenderHelper {
    public struct Element {
        public var node: Node
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
        projectionMatrix = currentCameraNode.camera!.projectionMatrix(for: drawableSize)
    }

    public func elements() -> any Sequence<Element> {
        // TODO: concat node's transform with parent node's transforms

        scene.root.allNodes().compactMap { node in
            guard let geometry = node.geometry else {
                return nil
            }
            // TODO: Move this all into element.
            let modelMatrix = node.transform.matrix
            let modelViewMatrix = viewMatrix * modelMatrix
            let modelViewProjectionMatrix = projectionMatrix * viewMatrix * modelMatrix
            let modelNormalMatrix = simd_float3x3(truncating: node.transform.matrix).inverse

            return Element(node: node, modelMatrix: modelMatrix, modelViewMatrix: modelViewMatrix, modelViewProjectionMatrix: modelViewProjectionMatrix, modelNormalMatrix: modelNormalMatrix)
        }
        .lazy
    }
}
