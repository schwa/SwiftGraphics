import Foundation

public struct Identified<ID, Content>: Identifiable where ID: Hashable {
    public var id: ID
    public var content: Content

    public init(id: ID, content: Content) {
        self.id = id
        self.content = content
    }
}

public extension Identified where ID == UUID {
    init(_ content: Content) {
        id = .init()
        self.content = content
    }
}

extension Identified: Equatable where Content: Equatable {
}

extension Identified: Comparable where Content: Comparable {
    public static func < (lhs: Identified<ID, Content>, rhs: Identified<ID, Content>) -> Bool {
        lhs.content < rhs.content
    }
}

extension Identified: Encodable where ID: Encodable, Content: Encodable {
}

extension Identified: Decodable where ID: Decodable, Content: Decodable {
}

extension Identified: Sendable where ID: Sendable, Content: Sendable {
}

public extension Array {
    func identifiedByIndex() -> [Identified<Int, Element>] {
        enumerated().map {
            Identified(id: $0.offset, content: $0.element)
        }
    }
}
