import simd

// MARK: simd_float3x4

public extension simd_float3x4 {
    static func scale(_ s: SIMD3<Float>) -> simd_float3x4 {
        simd_float3x4([s.x, 0, 0, 0], [0, s.y, 0, 0], [0, 0, s.z, 0])
    }
}

public extension simd_float3x4 {
    init(_ other: simd_float4x4) {
        self = simd_float3x4(columns: (other.columns.0, other.columns.1, other.columns.2))
    }
}
