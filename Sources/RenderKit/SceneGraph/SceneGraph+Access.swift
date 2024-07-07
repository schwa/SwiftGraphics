import Foundation
import SwiftUI

// TODO: This file needs a massive rewrite.
// Eveyrthing should be in terms of NodeAccessors not IndexPaths.
// We need convenience to access nodes by label, by id and by accessor
// We also need ways to query the graph = queries should (generally?) return accessors
// Query by content type woudl be nice

public struct NodeAccessor: Hashable {
    var path: IndexPath
}

public extension Binding where Value == SceneGraph {
    func binding(for label: String) -> Binding<Node?> {
        guard let indexPath = wrappedValue.firstIndexPath(label: label) else {
            fatalError()
        }
        return Binding<Node?> {
            wrappedValue[accessor: NodeAccessor(path: indexPath)]
        }
        set: {
            wrappedValue[accessor: NodeAccessor(path: indexPath)] = $0
        }
    }

    func binding(for indexPath: IndexPath) -> Binding<Node?> {
        Binding<Node?> {
            wrappedValue[accessor: NodeAccessor(path: indexPath)]
        }
        set: {
            print("SETTING")
            wrappedValue[accessor: NodeAccessor(path: indexPath)] = $0
        }
    }

    func binding(for indexPath: IndexPath) -> Binding<Node> {
        Binding<Node> {
            wrappedValue[accessor: NodeAccessor(path: indexPath)]!
        }
        set: {
            print("SETTING")
            wrappedValue[accessor: NodeAccessor(path: indexPath)] = $0
        }
    }
}

// TODO: Cleanup.
public extension SceneGraph {
    // @available(*, deprecated, message: "Deprecated")
    func firstIndexPath(matching predicate: (Node, IndexPath) -> Bool) -> IndexPath? {
        root.allIndexedNodes().first { node, indexPath in
            predicate(node, indexPath)
        }?.1
    }

    // @available(*, deprecated, message: "Deprecated")
    func firstIndexPath(id: Node.ID) -> IndexPath? {
        firstIndexPath { node, _ in
            node.id == id
        }
    }

    // @available(*, deprecated, message: "Deprecated")
    func firstIndexPath(label: String) -> IndexPath? {
        firstIndexPath { node, _ in
            node.label == label
        }
    }

    // @available(*, deprecated, message: "Deprecated")
    func node(for label: String) -> Node? {
        root.allIndexedNodes().first { $0.node.label == label }?.node
    }

    // @available(*, deprecated, message: "Deprecated")
    func accessor(for label: String) -> NodeAccessor? {
        guard let path = root.allIndexedNodes().first(where: { $0.node.label == label })?.path else {
            return nil
        }
        return .init(path: path)
    }

    // @available(*, deprecated, message: "Deprecated")
    func accessor(for id: Node.ID) -> NodeAccessor? {
        guard let path = root.allIndexedNodes().first(where: { $0.node.id == id })?.path else {
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

    // @available(*, deprecated, message: "Deprecated")
    mutating func modify <R>(label: String, _ block: (inout Node?) throws -> R) rethrows -> R {
        guard let accessor = accessor(for: label) else {
            fatalError()
        }
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
    }

    // @available(*, deprecated, message: "Deprecated")
    mutating func modify <R>(id: Node.ID, _ block: (inout Node?) throws -> R) rethrows -> R {
        guard let accessor = accessor(for: id) else {
            fatalError()
        }
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
    }

    // @available(*, deprecated, message: "Deprecated")
    mutating func modify <R>(node: Node, _ block: (inout Node?) throws -> R) rethrows -> R {
        guard let accessor = accessor(for: node.id) else {
            fatalError()
        }
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
    }


    // @available(*, deprecated, message: "Deprecated")
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
