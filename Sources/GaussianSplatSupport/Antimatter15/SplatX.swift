import GaussianSplatShaders
import simd

public extension SplatX {
    init(_ splat: SplatB) {
        self = convertSplatBToSplatX(splat: splat)
    }
}

extension SplatX: @unchecked @retroactive Sendable {
}

extension SplatX: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.position == rhs.position
            && lhs.color == rhs.color
            && lhs.u1 == rhs.u1
            && lhs.u2 == rhs.u2
            && lhs.u3 == rhs.u3
    }
}

extension SplatX: SplatProtocol {
    public var floatPosition: SIMD3<Float> {
        SIMD3<Float>(position)
    }
}

public func convertSplatBToSplatX(splat: SplatB) -> SplatX {
    // Extract position
    let position = splat.position

    // Copy color components directly
    let color = splat.color

    // Extract scale
    let scale = splat.scale

    // Map rotation components from UInt8 (0..255) to Float in [-1, 1]
    let rot: [Float] = splat.rotation.map { (Float($0) - 128.0) / 128.0 }

    // Calculate individual matrix elements (flattened)
    let m = [
        1.0 - 2.0 * (rot[2] * rot[2] + rot[3] * rot[3]),
        2.0 * (rot[1] * rot[2] + rot[0] * rot[3]),
        2.0 * (rot[1] * rot[3] - rot[0] * rot[2]),

        2.0 * (rot[1] * rot[2] - rot[0] * rot[3]),
        1.0 - 2.0 * (rot[1] * rot[1] + rot[3] * rot[3]),
        2.0 * (rot[2] * rot[3] + rot[0] * rot[1]),

        2.0 * (rot[1] * rot[3] + rot[0] * rot[2]),
        2.0 * (rot[2] * rot[3] - rot[0] * rot[1]),
        1.0 - 2.0 * (rot[1] * rot[1] + rot[2] * rot[2])
    ].enumerated().map { $0.element * scale[$0.offset / 3] }

    // Compute sigma values
    var sigma = [
        m[0] * m[0] + m[3] * m[3] + m[6] * m[6],
        m[0] * m[1] + m[3] * m[4] + m[6] * m[7],
        m[0] * m[2] + m[3] * m[5] + m[6] * m[8],
        m[1] * m[1] + m[4] * m[4] + m[7] * m[7],
        m[1] * m[2] + m[4] * m[5] + m[7] * m[8],
        m[2] * m[2] + m[5] * m[5] + m[8] * m[8]
    ]

    sigma = sigma.map { $0 * 4 }

    // Convert sigma values into simd_half2 pairs
    let u1 = simd_half2(Float16(sigma[0]), Float16(sigma[1]))
    let u2 = simd_half2(Float16(sigma[2]), Float16(sigma[3]))
    let u3 = simd_half2(Float16(sigma[4]), Float16(sigma[5]))

    // Construct and return the SplatX
    return SplatX(
        position: SIMD3<Float>(position),
        u1: u1,
        u2: u2,
        u3: u3,
        color: color
    )
}

extension simd_float4x4 {
    init(_ m00: Float, _ m01: Float, _ m02: Float, _ m03: Float, _ m10: Float, _ m11: Float, _ m12: Float, _ m13: Float, _ m20: Float, _ m21: Float, _ m22: Float, _ m23: Float, _ m30: Float, _ m31: Float, _ m32: Float, _ m33: Float) {
        self = simd_float4x4(
            simd_float4(m00, m01, m02, m03),
            simd_float4(m10, m11, m12, m13),
            simd_float4(m20, m21, m22, m23),
            simd_float4(m30, m31, m32, m33)
        )
    }
}
