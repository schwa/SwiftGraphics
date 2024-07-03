import Foundation
import SwiftGraphicsSupport

public extension Node {
    func contains(_ indexPath: IndexPath) -> Bool {
        guard let index = indexPath.first else {
            return true
        }
        guard index < children.endIndex else {
            return false
        }
        let child = children[index]
        let indexPath = indexPath.dropFirst()
        return child.contains(indexPath)
    }

    subscript(indexPath indexPath: IndexPath) -> Node {
        get {
            guard let index = indexPath.first else {
                return self
            }
            let child = children[index]
            let indexPath = indexPath.dropFirst()
            if indexPath.isEmpty {
                return child
            }
            else {
                return child[indexPath: indexPath]
            }
        }
        set {
            guard let index = indexPath.first else {
                self = newValue
                return
            }
            let indexPath = indexPath.dropFirst()
            if indexPath.isEmpty {
                children[index] = newValue
            }
            else {
                children[index][indexPath: indexPath] = newValue
            }
        }
    }
}

public extension Node {
    func allNodes() -> any Sequence<Node> {
        AnySequence {
            TreeIterator(mode: .depthFirst, root: self, children: \.children)
        }
    }
    func allIndexedNodes() -> any Sequence<(Node, IndexPath)> {
        AnySequence {
            TreeIterator(mode: .depthFirst, root: (self, IndexPath())) { node, path in
                node.children.enumerated().map { index, node in
                    (node, path + [index])
                }
            }
        }
    }
}

public extension Node {
    func dump() -> String {
        var s = ""
        for (node, path) in allIndexedNodes() {
            let indent = String(repeating: "  ", count: path.count)
            print("\(indent)Node(id: \"\(node.id)\", transform: \(node.transform), indexPath: #\(path))", to: &s)
            if let content = node.content {
                print("\(indent)  content: \(content))", to: &s)
            }
        }
        return s
    }
}
