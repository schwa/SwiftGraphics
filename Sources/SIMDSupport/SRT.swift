import simd

/**
 A type to represent a 3d transformation as a concatenation of a rotation, a translation and a scale.
 */
public struct SRT {
    public var scale: SIMD3<Float>
    public var rotation: Rotation
    public var translation: SIMD3<Float>

    public init(scale: SIMD3<Float> = .unit, rotation: Rotation = .identity, translation: SIMD3<Float> = .zero) {
        self.scale = scale
        self.rotation = rotation
        self.translation = translation
    }

    public var matrix: simd_float4x4 {
        let scaleMatrix = simd_float4x4(scale: scale)
        let rotationMatrix = rotation.matrix
        let translationMatrix = simd_float4x4(translate: translation)
        return translationMatrix * rotationMatrix * scaleMatrix
    }
}

extension SRT: Sendable {
}

extension SRT: Hashable {
    public func hash(into hasher: inout Hasher) {
        scale.altHash(into: &hasher)
        rotation.hash(into: &hasher)
        translation.altHash(into: &hasher)
    }
}

public extension SRT {
    init(scale: SIMD3<Float> = .unit, rotation: simd_quatf, translation: SIMD3<Float> = .zero) {
        self.init(scale: scale, rotation: .quaternion(rotation), translation: translation)
    }

    init(scale: SIMD3<Float> = .unit, rotation: RollPitchYaw, translation: SIMD3<Float> = .zero) {
        self.init(scale: scale, rotation: .rollPitchYaw(rotation), translation: translation)
    }

    init(scale: SIMD3<Float> = .unit, rotation: simd_float4x4, translation: SIMD3<Float> = .zero) {
        let rotation = simd_quatf(rotation)
        self = .init(scale: scale, rotation: rotation, translation: translation)
    }
}

// MARK: -

extension SRT: CustomStringConvertible {
    public var description: String {
        "SRT(\(innerDescription))"
    }

    var innerDescription: String {
        let scale = scale == .unit ? nil : "scale: [\(scale.x.formatted()), \(scale.y.formatted()), \(scale.z.formatted())]"
        let rotation = rotation == .identity ? nil : "rotation: \(rotation)"
        let translation = translation == .zero ? nil : "translation: [\(translation.x.formatted()), \(translation.y.formatted()), \(translation.z.formatted())]"
        return [scale, rotation, translation].compactMap({ $0 }).joined(separator: ",")
    }
}
