import Foundation

public struct NodeAccessor: Hashable {
    var path: IndexPath
}

public extension SceneGraph {

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
