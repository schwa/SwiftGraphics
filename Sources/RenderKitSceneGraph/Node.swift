import BaseSupport
import Foundation
import os
import SIMDSupport
public struct Node: Identifiable, Sendable {
    /// The type of content that can be stored in the node.
    public typealias Content = any Sendable

    /// A unique identifier for the node.
    public var id: TrivialID {
        didSet {
            updateGeneration(new: id, old: oldValue)
        }
    }

    /// Indicates whether the node is enabled or disabled.
    public var isEnabled: Bool {
        didSet {
            updateGeneration(new: isEnabled, old: oldValue)
        }
    }

    /// A descriptive label for the node.
    public var label: String {
        didSet {
            updateGeneration(new: label, old: oldValue)
        }
    }

    /// The transformation applied to this node, affecting its position, rotation, and scale.
    public var transform: Transform {
        didSet {
            updateGeneration(new: transform, old: oldValue)
        }
    }

    /// An array of child nodes belonging to this node.
    public var children: [Self] {
        didSet {
            updateGeneration(new: children.map(\.generationID), old: oldValue.map(\.generationID))
        }
    }

    /// The content stored in this node, if any.
    public var content: (Content)? {
        didSet {
            changeCount += 1
        }
    }

    /// A counter that increments whenever the node or its properties change.
    public var changeCount: Int = 0

    // IDEA: Rename
    /// A unique identifier that changes whenever the node or its properties are modified.
    public var generationID: AnyHashable {
        Pair(id, changeCount)
    }

    /// Initializes a new Node with the given properties.
    ///
    /// - Parameters:
    ///   - label: A descriptive label for the node. Defaults to an empty string.
    ///   - transform: The transformation applied to the node. Defaults to the identity transform.
    ///   - content: The content to be stored in the node. Defaults to nil.
    ///   - children: An array of child nodes. Defaults to an empty array.
    public init(label: String = "", transform: Transform = .identity, content: (Content)? = nil, children: [Self] = []) {
        self.id = TrivialID(for: Self.self)
        self.isEnabled = true
        self.label = label
        self.transform = transform
        self.content = content
        self.children = children
    }

    /// Updates the generation of the node if the new value is different from the old value.
    ///
    /// - Parameters:
    ///   - new: The new value to compare.
    ///   - old: The old value to compare against.
    public mutating func updateGeneration<T>(new: T, old: T) where T: Equatable {
        if new != old {
            changeCount += 1
        }
    }

    /// Updates the generation of the node if the new optional value is different from the old optional value.
    ///
    /// - Parameters:
    ///   - new: The new optional value to compare.
    ///   - old: The old optional value to compare against.
    public mutating func updateGeneration<T>(new: T?, old: T?) where T: Equatable {
        if new != old {
            changeCount += 1
        }
    }
}

extension Node: Equatable {
    // TODO: This is not true equality. Maybe put into a "PartialEquality" (gross: overloads with Rust term?) protocol? "GenerationEquality"
    /// Compares two nodes for equality based on their id and generationID.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side node to compare.
    ///   - rhs: The right-hand side node to compare.
    /// - Returns: True if the nodes are considered equal, false otherwise.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.generationID == rhs.generationID
    }
}

// MARK: -

extension Node: CustomDebugStringConvertible {
    /// Provides a debug description of the node, including its id, label, content, and children.
    public var debugDescription: String {
        "Node(id: \(id), label: \(label) content: \(content.map(String.init(describing:)) ?? "<nil>"), children: \(children))"
    }
}
