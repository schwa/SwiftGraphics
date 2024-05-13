import simd
import SIMDSupport

public struct SimpleVertex {
    public var packedPosition: PackedFloat3
    public var packedNormal: PackedFloat3
    public var textureCoordinate: SIMD2<Float>

    public init(packedPosition: PackedFloat3, packedNormal: PackedFloat3, textureCoordinate: SIMD2<Float> = .zero) {
        self.packedPosition = packedPosition
        self.packedNormal = packedNormal
        self.textureCoordinate = textureCoordinate
    }
}

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

    init(position: SIMD3<Float>, normal: SIMD3<Float>, textureCoordinate: SIMD2<Float> = .zero) {
        self = .init(packedPosition: PackedFloat3(position), packedNormal: PackedFloat3(normal), textureCoordinate: textureCoordinate)
    }
}

extension SimpleVertex: @unchecked Sendable {
}

extension SimpleVertex: Equatable {
}

extension SimpleVertex: Hashable {
}

