import BaseSupport
import Foundation
import os
import SIMDSupport

public struct Node: Identifiable, Sendable, Equatable {
    public typealias Content = any Sendable

    public var id: TrivialID {
        didSet {
            updateGeneration(new: id, old: oldValue)
        }
    }

    public var isEnabled: Bool {
        didSet {
            updateGeneration(new: isEnabled, old: oldValue)
        }
    }

    public var label: String {
        didSet {
            updateGeneration(new: label, old: oldValue)
        }
    }

    public var transform: Transform {
        didSet {
            updateGeneration(new: transform, old: oldValue)
        }
    }

    public var children: [Self] {
        didSet {
            updateGeneration(new: children.map(\.generationID), old: oldValue.map(\.generationID))
        }
    }

    public var content: (Content)? {
        didSet {
            changeCount += 1
        }
    }

    public var changeCount: Int = 0

    // IDEA: Rename
    public var generationID: AnyHashable {
        Pair(id, changeCount)
    }

    public init(label: String = "", transform: Transform = .identity, content: (Content)? = nil, children: [Self] = []) {
        self.id = TrivialID(for: Self.self)
        self.isEnabled = true
        self.label = label
        self.transform = transform
        self.content = content
        self.children = children
    }

    public mutating func updateGeneration<T>(new: T, old: T) where T: Equatable {
        if new != old {
            changeCount += 1
        }
    }

    public mutating func updateGeneration<T>(new: T?, old: T?) where T: Equatable {
        if new != old {
            changeCount += 1
        }
    }

    // TODO: This is not true equality. Maybe put into a "PartialEquality" (gross: overloads with Rust term?) protocol? "GenerationEquality"
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.generationID == rhs.generationID
    }
}

// MARK: -

extension Node: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Node(id: \(id), label: \(label) content: \(content.map(String.init(describing:)) ?? "<nil>"), children: \(children))"
    }
}
