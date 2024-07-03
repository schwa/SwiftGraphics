import Foundation
import os
import SIMDSupport
import SwiftGraphicsSupport

public struct SceneGraph: Equatable, Sendable {
    public var root: Node

    public var currentCameraPath: IndexPath?

    public init(root: Node) {
        self.root = root
        self.currentCameraPath = root.allIndexedNodes().first { $0.0.camera != nil }?.1
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

// MARK: -

extension SceneGraph {
    func firstIndexPath(matching predicate: (Node, IndexPath) -> Bool) -> IndexPath? {
        root.allIndexedNodes().first { node, indexPath in
            predicate(node, indexPath)
        }?.1
    }

    func firstIndexPath(id: Node.ID) -> IndexPath? {
        firstIndexPath { node, _ in
            node.id == id
        }
    }

    func firstIndexPath(label: String) -> IndexPath? {
        firstIndexPath { node, _ in
            node.label == label
        }
    }
}

public extension SceneGraph {
    var currentCameraNode: Node? {
        get {
            guard let currentCameraPath else {
                return nil
            }
            return root[indexPath: currentCameraPath]
        }
        set {
            if let newValue {
                root[indexPath: currentCameraPath!] = newValue
            }
            else {
                currentCameraPath = nil
            }
        }
    }
}
