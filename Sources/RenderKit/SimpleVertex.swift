import RenderKitShaders
import simd

public extension SimpleVertex {
    var position: SIMD3<Float> {
        get {
            return SIMD3<Float>(packedPosition)
        }
        set {
            packedPosition = PackedFloat3(newValue)
        }
    }

    var normal: SIMD3<Float> {
        get {
            return SIMD3<Float>(packedNormal)
        }
        set {
            packedNormal = PackedFloat3(newValue)
        }
    }

    init(position: SIMD3<Float>, normal: SIMD3<Float>, textureCoordinate: SIMD2<Float>) {
        self = .init(packedPosition: PackedFloat3(position), packedNormal: PackedFloat3(normal), textureCoordinate: textureCoordinate)
    }
}

extension SimpleVertex: @unchecked Sendable {
}

extension SimpleVertex: Equatable {
    public static func == (lhs: SimpleVertex, rhs: SimpleVertex) -> Bool {
        lhs.packedPosition == rhs.packedPosition && lhs.packedNormal == rhs.packedNormal && lhs.textureCoordinate == rhs.textureCoordinate
    }
}

extension SimpleVertex: Hashable {
    public func hash(into hasher: inout Hasher) {
        packedPosition.hash(into: &hasher)
        packedNormal.hash(into: &hasher)
        textureCoordinate.hash(into: &hasher)
    }
}
