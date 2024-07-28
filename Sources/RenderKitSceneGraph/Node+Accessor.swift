import BaseSupport
import Foundation
import SwiftUI

// IDEA: Query by content type would be nice

public extension Node {
    /// Represents a path to a specific node in a hierarchical structure.
    /// Used for efficient node access and modification.
    struct Accessor: Hashable, Sendable {
        /// The underlying IndexPath representing the path to a specific node in the tree.
        internal var path: IndexPath

        /// Initializes an Accessor with the given IndexPath.
        ///
        /// - Parameter path: The IndexPath representing the path to a node.
        internal init(_ path: IndexPath) {
            self.path = path
        }

        /// Initializes an empty Accessor, representing the root of the tree.
        public init() {
            self.path = .init()
        }
    }

    /// Accesses a node in the tree using the provided accessor.
    ///
    /// - Parameter accessor: The Accessor indicating the path to the desired node.
    /// - Returns: The node at the specified path.
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
    /// Returns a sequence of all nodes in the tree.
    ///
    /// - Returns: A sequence containing all nodes in the tree.
    func allNodes() -> any Sequence<Node> {
        AnySequence {
            TreeIterator(mode: .depthFirst, root: self, children: \.children)
        }
    }

    /// Returns a sequence of all nodes in the tree along with their accessors.
    ///
    /// - Returns: A sequence of tuples containing nodes and their corresponding accessors.
    func allAccessors() -> any Sequence<(node: Node, accessor: Accessor)> {
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
    /// Finds the first accessor that matches the given predicate.
    ///
    /// - Parameter predicate: A closure that takes a Node and an Accessor and returns a Bool.
    /// - Returns: The first Accessor that satisfies the predicate, or nil if none is found.
    func firstAccessor(matching predicate: (Node, Accessor) -> Bool) -> Accessor? {
        allAccessors().first { node, accessor in
            predicate(node, accessor)
        }?.accessor
    }

    /// Finds the first node that matches the given predicate.
    ///
    /// - Parameter predicate: A closure that takes a Node and an Accessor and returns a Bool.
    /// - Returns: The first Node that satisfies the predicate, or nil if none is found.
    func firstNode(matching predicate: (Node, Accessor) -> Bool) -> Node? {
        allAccessors().first { node, accessor in
            predicate(node, accessor)
        }?.node
    }
}

public extension Node {
    /// Finds the first accessor for a node with the given ID.
    ///
    /// - Parameter id: The ID of the node to find.
    /// - Returns: The Accessor for the node with the given ID, or nil if not found.
    func firstAccessor(id: Node.ID) -> Accessor? {
        firstAccessor { node, _ in
            node.id == id
        }
    }

    /// Finds the first accessor for a node with the given label.
    ///
    /// - Parameter label: The label of the node to find.
    /// - Returns: The Accessor for the node with the given label, or nil if not found.
    func firstAccessor(label: String) -> Accessor? {
        firstAccessor { node, _ in
            node.label == label
        }
    }

    /// Finds the first node with the given ID.
    ///
    /// - Parameter id: The ID of the node to find.
    /// - Returns: The Node with the given ID, or nil if not found.
    func firstNode(id: Node.ID) -> Node? {
        firstNode { node, _ in
            node.id == id
        }
    }

    /// Finds the first node with the given label.
    ///
    /// - Parameter label: The label of the node to find.
    /// - Returns: The Node with the given label, or nil if not found.
    func firstNode(label: String) -> Node? {
        firstNode { node, _ in
            node.label == label
        }
    }
}

// MARK: -

public extension SceneGraph {
    /// Accesses a node in the scene graph using the provided accessor.
    ///
    /// - Parameter accessor: The Accessor indicating the path to the desired node.
    /// - Returns: The node at the specified path, or nil if not found.
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
    /// Returns a sequence of all nodes in the tree.
    ///
    /// - Returns: A sequence containing all nodes in the tree.
    func allNodes() -> any Sequence<Node> {
        root.allNodes()
    }

    /// Returns a sequence of all nodes in the tree along with their accessors.
    ///
    /// - Returns: A sequence of tuples containing nodes and their corresponding accessors.
    func allAccessors() -> any Sequence<(node: Node, accessor: Node.Accessor)> {
        root.allAccessors()
    }
}

public extension SceneGraph {
    /// Finds the first accessor for a node with the given ID in the scene graph.
    ///
    /// - Parameter id: The ID of the node to find.
    /// - Returns: The Accessor for the node with the given ID, or nil if not found.
    func firstAccessor(id: Node.ID) -> Node.Accessor? {
        root.firstAccessor(id: id)
    }

    /// Finds the first accessor for a node with the given label in the scene graph.
    ///
    /// - Parameter label: The label of the node to find.
    /// - Returns: The Accessor for the node with the given label, or nil if not found.
    func firstAccessor(label: String) -> Node.Accessor? {
        root.firstAccessor(label: label)
    }

    /// Finds the first node with the given ID in the scene graph.
    ///
    /// - Parameter id: The ID of the node to find.
    /// - Returns: The Node with the given ID, or nil if not found.
    func firstNode(id: Node.ID) -> Node? {
        root.firstNode(id: id)
    }

    /// Finds the first node with the given label in the scene graph.
    ///
    /// - Parameter label: The label of the node to find.
    /// - Returns: The Node with the given label, or nil if not found.
    func firstNode(label: String) -> Node? {
        root.firstNode(label: label)
    }
}

public extension SceneGraph {
    /// Modifies a node in the scene graph using the provided accessor and modification closure.
    ///
    /// - Parameters:
    ///   - accessor: The Accessor indicating the path to the node to modify.
    ///   - block: A closure that takes an inout Node? and returns a value of type R.
    /// - Returns: The value returned by the modification closure.
    /// - Throws: Rethrows any error thrown by the modification closure.
    mutating func modify<R>(accessor: Node.Accessor, _ block: (inout Node?) throws -> R) rethrows -> R {
        var node = self[accessor: accessor]
        let result = try block(&node)
        self[accessor: accessor] = node
        return result
    }

    /// Modifies a node in the scene graph with the given label using the provided modification closure.
    ///
    /// - Parameters:
    ///   - label: The label of the node to modify.
    ///   - block: A closure that takes an inout Node? and returns a value of type R.
    /// - Returns: The value returned by the modification closure.
    /// - Throws: BaseError.missingValue if the node is not found, or rethrows any error thrown by the modification closure.
    mutating func modify<R>(label: String, _ block: (inout Node?) throws -> R) throws -> R {
        guard let accessor = firstAccessor(label: label) else {
            throw BaseError.missingValue
        }
        return try modify(accessor: accessor, block)
    }

    /// Modifies a node in the scene graph with the given ID using the provided modification closure.
    ///
    /// - Parameters:
    ///   - id: The ID of the node to modify.
    ///   - block: A closure that takes an inout Node? and returns a value of type R.
    /// - Returns: The value returned by the modification closure.
    /// - Throws: BaseError.missingValue if the node is not found, or rethrows any error thrown by the modification closure.
    mutating func modify<R>(id: Node.ID, _ block: (inout Node?) throws -> R) throws -> R {
        guard let accessor = firstAccessor(id: id) else {
            throw BaseError.missingValue
        }
        return try modify(accessor: accessor, block)
    }

    /// Modifies a specific node in the scene graph using the provided modification closure.
    ///
    /// - Parameters:
    ///   - node: The node to modify.
    ///   - block: A closure that takes an inout Node? and returns a value of type R.
    /// - Returns: The value returned by the modification closure.
    /// - Throws: BaseError.missingValue if the node is not found, or rethrows any error thrown by the modification closure.
    mutating func modify<R>(node: Node, _ block: (inout Node?) throws -> R) throws -> R {
        try modify(id: node.id, block)
    }
}

// MARK: -

public extension Binding where Value == SceneGraph {
    /// Creates a binding for a node with the given label in the scene graph.
    ///
    /// - Parameter label: The label of the node to bind to.
    /// - Returns: A Binding to the node with the given label.
    /// - Precondition: A node with the given label must exist in the scene graph.
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

    /// Creates a binding for a node at the given accessor in the scene graph.
    ///
    /// - Parameter accessor: The Accessor indicating the path to the node.
    /// - Returns: A Binding to the node at the given accessor.
    func binding(for accessor: Node.Accessor) -> Binding<Node?> {
        Binding<Node?> {
            wrappedValue[accessor: accessor]
        }
        set: {
            wrappedValue[accessor: accessor] = $0
        }
    }

    /// Creates a non-optional binding for a node at the given accessor in the scene graph.
    ///
    /// - Parameter accessor: The Accessor indicating the path to the node.
    /// - Returns: A Binding to the node at the given accessor.
    /// - Precondition: A node must exist at the given accessor.
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
