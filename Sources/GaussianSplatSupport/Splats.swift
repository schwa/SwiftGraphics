import BaseSupport
import GaussianSplatShaders
import Metal
import MetalSupport
import simd
import SIMDSupport

public protocol SplatProtocol: Equatable, Sendable {
    var floatPosition: SIMD3<Float> { get }
}

public struct SplatB: Equatable, Sendable {
    public var position: PackedFloat3
    public var scale: PackedFloat3
    public var color: SIMD4<UInt8>
    public var rotation: SIMD4<UInt8>

    public init(position: PackedFloat3, scale: PackedFloat3, color: SIMD4<UInt8>, rotation: SIMD4<UInt8>) {
        self.position = position
        self.scale = scale
        self.color = color
        self.rotation = rotation
    }
}

// Metal Debugger: half3 position, half4 color, half3 cov_a, half3 cov_b
public struct SplatC: Equatable, Sendable {
    public var position: PackedHalf3
    public var color: PackedHalf4
    public var cov_a: PackedHalf3
    public var cov_b: PackedHalf3

    public init(position: PackedHalf3, color: PackedHalf4, cov_a: PackedHalf3, cov_b: PackedHalf3) {
        self.position = position
        self.color = color
        self.cov_a = cov_a
        self.cov_b = cov_b
    }
}

extension SplatC: SplatProtocol {
    public var floatPosition: SIMD3<Float> {
        .init(position)
    }
}

public struct SplatD: Equatable {
    public var position: PackedFloat3
    public var scale: PackedFloat3
    public var color: SIMD4<Float>
    public var rotation: Rotation

    public init(position: PackedFloat3, scale: PackedFloat3, color: SIMD4<Float>, rotation: Rotation) {
        self.position = position
        self.scale = scale
        self.color = color
        self.rotation = rotation
    }
}

public extension SplatB {
    init(_ other: SplatD) {
        let color = SIMD4<UInt8>(other.color * 255)
        let rotation_vector = other.rotation.quaternion.vectorRealFirst
        let rotation = ((rotation_vector / rotation_vector.length) * 128 + 128).clamped(to: 0...255)
        self = SplatB(position: other.position, scale: other.scale, color: color, rotation: SIMD4<UInt8>(rotation))
    }
}

public extension SplatC {
    init(_ other: SplatD) {
        let transform = simd_float3x3(other.rotation.quaternion) * simd_float3x3(diagonal: SIMD3<Float>(other.scale))
        let cov3D = transform * transform.transpose
        let cov_a = PackedHalf3(x: Float16(cov3D[0, 0]), y: Float16(cov3D[0, 1]), z: Float16(cov3D[0, 2]))
        let cov_b = PackedHalf3(x: Float16(cov3D[1, 1]), y: Float16(cov3D[1, 2]), z: Float16(cov3D[2, 2]))

        self = SplatC(position: PackedHalf3(SIMD3<Float>(other.position)), color: PackedHalf4(other.color), cov_a: cov_a, cov_b: cov_b)
    }
}

extension simd_quatf {
    var vectorRealFirst: simd_float4 {
        [vector.w, vector.x, vector.y, vector.z]
    }
}

// MARK: -

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
