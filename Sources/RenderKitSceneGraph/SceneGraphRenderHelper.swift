import BaseSupport
import Metal
import simd

public struct SceneGraphRenderHelper {
    public struct Element {
        public var node: Node
        // IDEA: Some of these should be calculated on the fly.
        public var modelMatrix: simd_float4x4
        public var modelViewMatrix: simd_float4x4
        public var modelViewProjectionMatrix: simd_float4x4
        public var modelNormalMatrix: simd_float3x3
    }

    public var scene: SceneGraph
    public var cameraMatrix: simd_float4x4
    public var viewMatrix: simd_float4x4
    public var projectionMatrix: simd_float4x4

    public init(scene: SceneGraph, cameraMatrix: simd_float4x4, viewMatrix: simd_float4x4? = nil, projectionMatrix: simd_float4x4) {
        self.scene = scene
        self.cameraMatrix = cameraMatrix
        self.viewMatrix = viewMatrix ?? cameraMatrix.inverse
        self.projectionMatrix = projectionMatrix
    }

    public func elements() -> any Sequence<Element> {
        var transformStack: [simd_float4x4] = []
        var events = TreeEventIterator(root: scene.root, children: \.children)
        let iterator = AnyIterator {
            while let event = events.next() {
                switch event {
                case .push(let node):
                    let modelMatrix: simd_float4x4
                    if transformStack.isEmpty {
                        modelMatrix = node.transform.matrix
                        transformStack = [modelMatrix]
                    } else {
                        guard let parentTransform = transformStack.last else {
                            fatalError("Popping from empty transform stack")
                        }
                        modelMatrix = parentTransform * node.transform.matrix
                        transformStack.append(modelMatrix)
                    }
                    let modelViewMatrix = viewMatrix * modelMatrix
                    let modelViewProjectionMatrix = projectionMatrix * viewMatrix * modelMatrix
                    let modelNormalMatrix = simd_float3x3(truncating: node.transform.matrix).inverse
                    return Element(node: node, modelMatrix: modelMatrix, modelViewMatrix: modelViewMatrix, modelViewProjectionMatrix: modelViewProjectionMatrix, modelNormalMatrix: modelNormalMatrix)
                case .pop:
                    _ = transformStack.popLast()
                }
            }
            return nil
        }
        return AnySequence { iterator }
    }
}

public extension SceneGraphRenderHelper {
    init(scene: SceneGraph, targetColorAttachment: MTLRenderPassColorAttachmentDescriptor) throws {
        guard let texture = targetColorAttachment.texture else {
            throw BaseError.invalidParameter
        }
        let size = SIMD2<Float>(Float(texture.width), Float(texture.height))
        self.init(scene: scene, renderTargetSize: size)
    }

    init(scene: SceneGraph, renderTargetSize: SIMD2<Float>) {
        guard let currentCameraNode = scene.currentCameraNode else {
            fatalError("No current camera node in scene")
        }
        assert(renderTargetSize.x > 0 && renderTargetSize.y > 0)
        let cameraMatrix = currentCameraNode.transform.matrix
        let viewMatrix = cameraMatrix.inverse
        guard let projectionMatrix = currentCameraNode.camera?.projectionMatrix(for: renderTargetSize) else {
            fatalError("No camera in scene")
        }
        self.init(scene: scene, cameraMatrix: cameraMatrix, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
    }
}

// MARK: -

public struct TreeEventIterator<Node>: IteratorProtocol {
    private var stack: [(Node, Bool)]
    private let children: (Node) -> [Node]?

    public enum Event {
        case push(Node)
        case pop
    }

    public init(root: Node, children: @escaping (Node) -> [Node]?) {
        self.stack = [(root, false)]
        self.children = children
    }

    public mutating func next() -> Event? {
        while let (current, isVisited) = stack.popLast() {
            if isVisited {
                return .pop
            } else {
                stack.append((current, true))
                if let children = children(current) {
                    for child in children.reversed() {
                        stack.append((child, false))
                    }
                }
                return .push(current)
            }
        }
        return nil
    }
}

public extension TreeEventIterator {
    init(root: Node, children keyPath: KeyPath<Node, [Node]?>) {
        self.init(root: root) { node -> [Node]? in
            node[keyPath: keyPath]
        }
    }

    init(root: Node, children keyPath: KeyPath<Node, [Node]>) {
        self.init(root: root) { node -> [Node]? in
            node[keyPath: keyPath]
        }
    }
}
