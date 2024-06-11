import SIMDSupport
import SwiftGraphicsSupport

@resultBuilder public struct NodeBuilder {
    public static func buildBlock(_ nodes: [Node]...) -> [Node] {
        Array(nodes.joined())
    }

    public static func buildExpression(_ node: Node) -> [Node] {
        [node]
    }

    public static func buildExpression(_ nodes: [Node]) -> [Node] {
        nodes
    }

    public static func buildOptional(_ nodes: [Node]?) -> [Node] {
        nodes ?? []
    }

    public static func buildEither(first nodes: [Node]) -> [Node] {
        nodes
    }

    public static func buildEither(second nodes: [Node]) -> [Node] {
        nodes
    }
}

extension Node {
    public init(label: String = "", transform: Transform = .identity, content: Content? = nil, @NodeBuilder children: () throws -> [Node]) throws {
        self.id = TrivialID(for: Self.self)
        self.isEnabled = true
        self.label = label
        self.transform = transform
        self.content = content
        self.children = try children()
    }

}
