import Foundation

public struct NodeAccessor: Hashable {
    var path: IndexPath
}

// TODO: Cleanup.
public extension SceneGraph {
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

    // TODO: Rename
    func node(for label: String) -> Node? {
        root.allIndexedNodes().first(where: { $0.node.label == label })?.node
    }

    func accessor(for label: String) -> NodeAccessor? {
        guard let path = root.allIndexedNodes().first(where: { $0.node.label == label })?.path else {
            return nil
        }
        return .init(path: path)
    }

    subscript(accessor accessor: NodeAccessor) -> Node? {
        get {
            root[indexPath: accessor.path]
        }
        set {
            // TODO: FIXME
            root[indexPath: accessor.path] = newValue!
        }
    }

    mutating func modify <R>(label: String, _ block: (inout Node?) throws -> R) rethrows -> R {
        guard let accessor = accessor(for: label) else {
            fatalError()
        }
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
    }

    mutating func modify <R>(accessor: NodeAccessor, _ block: (inout Node?) throws -> R) rethrows -> R {
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
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
