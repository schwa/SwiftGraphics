import BaseSupport
import Foundation
import SwiftUI

// IDEA: Query by content type woudl be nice

// An opaque wrapper around IndexPath.
public extension Node {
    typealias Accessor = NodeAccessor
}

public struct NodeAccessor: Hashable, Sendable {
    var path: IndexPath

    init(_ path: IndexPath) {
        self.path = path
    }

    init() {
        self.path = .init()
    }
}

public extension Node {
    subscript(accessor accessor: Accessor) -> Node {
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
}

public extension Node {
    func allNodes() -> any Sequence<Node> {
        AnySequence {
            TreeIterator(mode: .depthFirst, root: self, children: \.children)
        }
    }

    func allNodes() -> any Sequence<(node: Node, accessor: Accessor)> {
        AnySequence {
            TreeIterator(mode: .depthFirst, root: (node: self, accessor: .init())) { node, accessor in
                node.children.enumerated().map { index, node in
                    (node: node, accessor: .init(accessor.path + [index]))
                }
            }
        }
    }
}

public extension Node {
    func firstAccessor(matching predicate: (Node, Accessor) -> Bool) -> Accessor? {
        allNodes().first { node, accessor in
            predicate(node, accessor)
        }?.accessor
    }
    func firstNode(matching predicate: (Node, Accessor) -> Bool) -> Node? {
        allNodes().first { node, accessor in
            predicate(node, accessor)
        }?.node
    }
}

public extension Node {
    func firstAccessor(id: Node.ID) -> Accessor? {
        firstAccessor { node, _ in
            node.id == id
        }
    }
    func firstAccessor(label: String) -> Accessor? {
        firstAccessor { node, _ in
            node.label == label
        }
    }

    func firstNode(id: Node.ID) -> Node? {
        firstNode { node, _ in
            node.id == id
        }
    }

    func firstNode(label: String) -> Node? {
        firstNode { node, _ in
            node.label == label
        }
    }
}

// MARK: -

public extension SceneGraph {
    subscript(accessor accessor: Node.Accessor) -> Node? {
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
}

public extension SceneGraph {
    func firstAccessor(id: Node.ID) -> Node.Accessor? {
        root.firstAccessor(id: id)
    }
    func firstAccessor(label: String) -> Node.Accessor? {
        root.firstAccessor(label: label)
    }

    func firstNode(id: Node.ID) -> Node? {
        root.firstNode(id: id)
    }

    func firstNode(label: String) -> Node? {
        root.firstNode(label: label)
    }
}

public extension SceneGraph {
    mutating func modify <R>(accessor: Node.Accessor, _ block: (inout Node?) throws -> R) rethrows -> R {
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
    }

    mutating func modify <R>(label: String, _ block: (inout Node?) throws -> R) throws -> R {
        guard let accessor = firstAccessor(label: label) else {
            throw BaseError.missingValue
        }
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
    }

    mutating func modify <R>(id: Node.ID, _ block: (inout Node?) throws -> R) throws -> R {
        guard let accessor = firstAccessor(id: id) else {
            throw BaseError.missingValue
        }
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
    }

    mutating func modify <R>(node: Node, _ block: (inout Node?) throws -> R) throws -> R {
        guard let accessor = firstAccessor(id: node.id) else {
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
        guard let accessor = wrappedValue.firstAccessor(label: label) else {
            fatalError("No node with label \(label) found in scene graph.")
        }
        return Binding<Node?> {
            wrappedValue[accessor: accessor]
        }
        set: {
            wrappedValue[accessor: accessor] = $0
        }
    }

    func binding(for accessor: Node.Accessor) -> Binding<Node?> {
        Binding<Node?> {
            wrappedValue[accessor: accessor]
        }
        set: {
            wrappedValue[accessor: accessor] = $0
        }
    }

    func binding(for accessor: Node.Accessor) -> Binding<Node> {
        Binding<Node> {
            guard let node = wrappedValue[accessor: accessor] else {
                fatalError("No node at accessor: \(accessor).")
            }
            return node
        }
        set: {
            wrappedValue[accessor: accessor] = $0
        }
    }
}
