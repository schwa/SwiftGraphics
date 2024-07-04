import Foundation
import Everything

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

public extension Array {
    func identifiedByIndex() -> [Identified<Int, Element>] {
        enumerated().map {
            Identified(id: $0.offset, content: $0.element)
        }
    }
}

public extension Array where Element: Identifiable {
    @discardableResult
    mutating func remove(identifiedBy id: Element.ID) -> Element {
        if let index = firstIndex(identifiedBy: id) {
            remove(at: index)
        }
        else {
            fatalError("No element identified by \(id)")
        }
    }
}
