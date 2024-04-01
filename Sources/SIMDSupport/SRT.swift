import simd

/**
 A type to represent a 3d transformation as a concatenation of a rotation, a translation and a scale.
 */
public struct SRT {
    public var scale: SIMD3<Float> = .unit
    public var rotation: simd_quatf = .identity
    public var translation: SIMD3<Float> = .zero

    public init(scale: SIMD3<Float> = .unit, rotation: simd_quatf = .identity, translation: SIMD3<Float> = .zero) {
        self.scale = scale
        self.rotation = rotation
        self.translation = translation
    }

    public var matrix: simd_float4x4 {
        let scaleMatrix = simd_float4x4(scale: scale)
        let rotationMatrix = simd_float4x4(rotation)
        let translationMatrix = simd_float4x4(translate: translation)
        return translationMatrix * rotationMatrix * scaleMatrix
    }
}

extension SRT: Sendable {
}

extension SRT: Hashable {
    public func hash(into hasher: inout Hasher) {
        scale.altHash(into: &hasher)
        rotation.altHash(into: &hasher)
        translation.altHash(into: &hasher)
    }
}

// MARK: -

extension SRT: Codable {
    enum CodingKeys: CodingKey {
        case scale
        case rotation
        case translation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scale = try container.decodeIfPresent([Float].self, forKey: .scale).map { SIMD3<Float>($0) } ?? .unit
        rotation = try container.decodeIfPresent([Float].self, forKey: .rotation).map { simd_quatf(vector: SIMD4<Float>($0)) } ?? .identity
        translation = try container.decodeIfPresent([Float].self, forKey: .translation).map { SIMD3<Float>($0) } ?? .zero
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scale.scalars, forKey: .scale)
        try container.encode(rotation.vector.scalars, forKey: .rotation)
        try container.encode(translation.scalars, forKey: .translation)
    }
}

extension SRT: CustomStringConvertible {
    public var description: String {
        "SRT(\(innerDescription))"
    }

    var innerDescription: String {
        let scale = scale == .unit ? nil : "scale: [\(scale.x.formatted()), \(scale.y.formatted()), \(scale.z.formatted())]"
        let rotation = rotation == .identity ? nil : "rotation: \(rotation.innerDescription)"
        let translation = translation == .zero ? nil : "translation: [\(translation.x.formatted()), \(translation.y.formatted()), \(translation.z.formatted())]"
        return [scale, rotation, translation].compactMap({ $0 }).joined(separator: ",")
    }
}
