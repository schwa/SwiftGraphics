import Foundation
import os
import SIMDSupport
import SwiftGraphicsSupport

public struct SceneGraph: Equatable, Sendable {
    public var root: Node

    public var currentCameraPath: IndexPath?

    public init(root: Node) {
        self.root = root
        self.currentCameraPath = root.allIndexedNodes().first { $0.node.camera != nil }?.1
    }

    public init() {
        self.root = Node()
        self.currentCameraPath = nil
    }

    public func pathTo(node needle: Node) -> IndexPath? {
        root.allIndexedNodes().first { node, _ in
            needle == node
        }?.1
    }
}
