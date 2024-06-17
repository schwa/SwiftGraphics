import Foundation
@preconcurrency import MetalKit
import os
import SIMDSupport
import SwiftGraphicsSupport

public struct SceneGraph: Equatable {
    public var root: Node

    public var currentCameraPath: IndexPath?

    public var currentCameraNode: Node? {
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

    public init(root: Node) {
        self.root = root
        self.currentCameraPath = root.allIndexedNodes().first(where: { $0.0.content?.camera != nil })?.1
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

public struct Node: Identifiable, Sendable, Equatable {
    public enum Content: Sendable, Equatable {
        case camera(Camera)
        case geometry(Geometry)
    }

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
            updateGeneration(new: children.map(\.generationID), old: oldValue.map(\.generationID), structural: true)
        }
    }

    public var content: Content? {
        didSet {
            updateGeneration(new: content, old: oldValue)
        }
    }

    public var generation: Int = 0

    public var generationID: AnyHashable {
        Pair(id, generation)
    }

    public init(label: String = "", transform: Transform = .identity, content: Content? = nil, children: [Self] = []) {
        self.id = TrivialID(for: Self.self)
        self.isEnabled = true
        self.label = label
        self.transform = transform
        self.content = content
        self.children = children
    }

    public mutating func updateGeneration<T>(new: T, old: T, structural: Bool = false) where T: Equatable {
        if new != old {
            generation += 1
        }
    }
}

extension Node: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.generationID == rhs.generationID
    }

    public func hash(into hasher: inout Hasher) {
        generationID.hash(into: &hasher)
    }
}

// MARK: -

extension Node: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Node(id: \(id), label: \(label) content: \(content.map(String.init(describing:)) ?? "<nil>"), children: \(children))"
    }
}

// MARK: -

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

// MARK: -

public extension Node.Content {
    // TODO: Return a non-optional?
    var geometry: Geometry? {
        get {
            if case let .geometry(value) = self {
                return value
            }
            else {
                return nil
            }
        }
        set {
            guard let newValue else {
                fatalError()
            }
            self = .geometry(newValue)
        }
    }

    // TODO: Return a non-optional?
    var camera: Camera? {
        get {
            if case let .camera(value) = self {
                return value
            }
            else {
                return nil
            }
        }
        set {
            guard let newValue else {
                fatalError()
            }
            self = .camera(newValue)
        }
    }
}

// MARK: -

public protocol MaterialProtocol: Sendable, Equatable {
}

public struct Geometry: Sendable, Equatable {
    public var mesh: MTKMesh
    public var materials: [any MaterialProtocol]

    public init(mesh: MTKMesh, materials: [any MaterialProtocol]) {
        self.mesh = mesh
        self.materials = materials
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.mesh == rhs.mesh else {
            return false
        }
        let lhs = lhs.materials.map { AnyEquatable($0) }
        let rhs = rhs.materials.map { AnyEquatable($0) }
        return lhs == rhs
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

extension Node.Content: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .camera(let camera):
            ".camera(\(camera))"
        case .geometry(let geometry):
            ".geometry(\(geometry))"
        }
    }
}

extension Geometry: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Geometry(mesh: \(mesh), materials: \(materials))"
    }
}

extension SceneGraph {
    func firstIndexPath(matching predicate: (Node, IndexPath) -> Bool) -> IndexPath? {
        root.allIndexedNodes().first { node, indexPath in
            predicate(node, indexPath)
        }?.1
    }

    func firstIndexPath(id: Node.ID) -> IndexPath? {
        firstIndexPath(matching: { node, _ in
            node.id == id
        })
    }

    func firstIndexPath(label: String) -> IndexPath? {
        firstIndexPath(matching: { node, _ in
            node.label == label
        })
    }
}
