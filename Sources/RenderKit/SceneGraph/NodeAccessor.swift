import BaseSupport
import Foundation
import SwiftUI

// TODO: This file needs a massive rewrite.
// Eveyrthing should be in terms of NodeAccessors not IndexPaths.
// We need convenience to access nodes by label, by id and by accessor
// We also need ways to query the graph = queries should (generally?) return accessors
// Query by content type woudl be nice

public struct NodeAccessor: Hashable, Sendable {
    var path: IndexPath

    init(_ path: IndexPath) {
        self.path = path
    }
}

public extension Node {
    subscript(accessor accessor: NodeAccessor) -> Node {
        get {
            guard let index = accessor.path.first else {
                return self
            }
            let child = children[index]
            let indexPath = accessor.path.dropFirst()
            if indexPath.isEmpty {
                return child
            }
            else {
                return child[accessor: .init(indexPath)]
            }
        }
        set {
            guard let index = accessor.path.first else {
                self = newValue
                return
            }
            let indexPath = accessor.path.dropFirst()
            if indexPath.isEmpty {
                children[index] = newValue
            }
            else {
                children[index][accessor: .init(indexPath)] = newValue
            }
        }
    }

    @available(*, deprecated, message: "Deprecated")
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
    func allIndexedNodes() -> any Sequence<(node: Node, path: IndexPath)> {
        AnySequence {
            TreeIterator(mode: .depthFirst, root: (node: self, path: IndexPath())) { node, path in
                node.children.enumerated().map { index, node in
                    (node: node, path: path + [index])
                }
            }
        }
    }
}

// MARK: -

public extension SceneGraph {
    @available(*, deprecated, message: "Deprecated")
    func firstIndexPath(matching predicate: (Node, IndexPath) -> Bool) -> IndexPath? {
        root.allIndexedNodes().first { node, indexPath in
            predicate(node, indexPath)
        }?.1
    }

    @available(*, deprecated, message: "Deprecated")
    func firstIndexPath(id: Node.ID) -> IndexPath? {
        firstIndexPath { node, _ in
            node.id == id
        }
    }

    @available(*, deprecated, message: "Deprecated")
    func firstIndexPath(label: String) -> IndexPath? {
        firstIndexPath { node, _ in
            node.label == label
        }
    }

    @available(*, deprecated, message: "Deprecated")
    func node(for label: String) -> Node? {
        root.allIndexedNodes().first { $0.node.label == label }?.node
    }

    @available(*, deprecated, message: "Deprecated")
    func accessor(for label: String) -> NodeAccessor? {
        guard let path = root.allIndexedNodes().first(where: { $0.node.label == label })?.path else {
            return nil
        }
        return .init(path)
    }

    @available(*, deprecated, message: "Deprecated")
    func accessor(for id: Node.ID) -> NodeAccessor? {
        guard let path = root.allIndexedNodes().first(where: { $0.node.id == id })?.path else {
            return nil
        }
        return .init(path)
    }

    subscript(accessor accessor: NodeAccessor) -> Node? {
        get {
            root[accessor: accessor]
        }
        set {
            guard let newValue else {
                // IDEA: There's no reason we can't delete the node here.
                fatalError("Cannot set node to nil")
            }
            root[accessor: accessor] = newValue
        }
    }

    mutating func modify <R>(accessor: NodeAccessor, _ block: (inout Node?) throws -> R) rethrows -> R {
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
    }

    mutating func modify <R>(label: String, _ block: (inout Node?) throws -> R) throws -> R {
        guard let accessor = accessor(for: label) else {
            throw BaseError.missingValue
        }
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
    }

    mutating func modify <R>(id: Node.ID, _ block: (inout Node?) throws -> R) throws -> R {
        guard let accessor = accessor(for: id) else {
            throw BaseError.missingValue
        }
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
    }

    mutating func modify <R>(node: Node, _ block: (inout Node?) throws -> R) throws -> R {
        guard let accessor = accessor(for: node.id) else {
            throw BaseError.missingValue
        }
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
    }
}



// MARK: -

public extension Binding where Value == SceneGraph {
    func binding(for label: String) -> Binding<Node?> {
        guard let indexPath = wrappedValue.firstIndexPath(label: label) else {
            fatalError("No node with label \(label) found in scene graph.")
        }
        return Binding<Node?> {
            wrappedValue[accessor: NodeAccessor(indexPath)]
        }
        set: {
            wrappedValue[accessor: NodeAccessor(indexPath)] = $0
        }
    }

    func binding(for indexPath: IndexPath) -> Binding<Node?> {
        Binding<Node?> {
            wrappedValue[accessor: NodeAccessor(indexPath)]
        }
        set: {
            wrappedValue[accessor: NodeAccessor(indexPath)] = $0
        }
    }

    func binding(for indexPath: IndexPath) -> Binding<Node> {
        Binding<Node> {
            guard let node = wrappedValue[accessor: NodeAccessor(indexPath)] else {
                fatalError("No node at indexPath \(indexPath)")
            }
            return node
        }
        set: {
            wrappedValue[accessor: NodeAccessor(indexPath)] = $0
        }
    }
}
