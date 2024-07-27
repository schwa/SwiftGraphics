import Foundation
import os

public struct SceneGraph: Equatable, Sendable {
    public var root: Node

    public var currentCameraAccessor: NodeAccessor?

    public init(root: Node) {
        self.root = root
        self.currentCameraAccessor = root.firstAccessor { node, _ in
            node.camera != nil
        }
    }

    public init() {
        self.root = Node()
        self.currentCameraAccessor = nil
    }
}
