import simd

public struct SimpleVertex {
    public var packedPosition: PackedFloat3
    public var packedNormal: PackedFloat3
    public var textureCoordinate: SIMD2<Float>
};

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

    init(position: PackedFloat3, normal: PackedFloat3, textureCoordinate: SIMD2<Float> = .zero) {
        packedPosition = position
        packedNormal = normal
        self.textureCoordinate = textureCoordinate
    }
}


extension SimpleVertex: @unchecked Sendable {
}

extension SimpleVertex: Equatable {
}

extension SimpleVertex: Hashable {
}

