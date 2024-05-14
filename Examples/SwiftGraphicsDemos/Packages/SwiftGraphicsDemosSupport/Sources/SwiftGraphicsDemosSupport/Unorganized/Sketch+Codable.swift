import Foundation
import SwiftUI

extension Sketch: Codable {
    enum CodingKeys: CodingKey {
        case elements
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        elements = try container.decode([Element].self, forKey: .elements)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(elements, forKey: .elements)
    }
}

extension Element: Codable {
    enum CodingKeys: CodingKey {
        case id
        case color
        case label
        case shape
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        color = Color.pink
        label = try container.decode(String.self, forKey: .label)
        shape = try container.decode(SketchShapeEnum.self, forKey: .shape)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(label, forKey: .label)
        try container.encode(shape, forKey: .shape)
    }
}
