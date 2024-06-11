import Foundation
import simd
import SwiftUI

public extension simd_float3x3 {
    @inlinable init(scale s: SIMD3<Float>) {
        self = simd_float3x3(columns: (
            [s.x, 0, 0],
            [0, s.y, 0],
            [0, 0, s.z]
        ))
    }

    @inlinable init(rotationAngle angle: Angle, axis: SIMD3<Float>) {
        self.init(simd_float4x4(simd_quaternion(Float(angle.radians), axis)))
    }

    @inlinable static func scaled(_ s: SIMD3<Float>) -> simd_float3x3 {
        simd_float3x3(scale: s)
    }

    @inlinable static func rotation(angle: Angle, axis: SIMD3<Float>) -> simd_float3x3 {
        simd_float3x3(simd_quaternion(Float(angle.radians), axis))
    }
}

public extension simd_float3x3 {
    @inlinable init(_ m: simd_float4x4) {
        self = simd_float3x3(columns: (
            m.columns.0.xyz,
            m.columns.1.xyz,
            m.columns.2.xyz
        ))
    }
}

public extension simd_float3x3 {
    @inlinable init(truncating other: simd_float4x4) {
        self = simd_float3x3(other.map(\.xyz).dropLast())
    }
}

public extension simd_float3x3 {
    @inlinable init(scalars: [Scalar]) {
        self = .identity
        self.scalars = scalars
    }

    @inlinable var scalars: [Scalar] {
        get {
            [
                columns.0.x, columns.0.y, columns.0.z,
                columns.1.x, columns.1.y, columns.1.z,
                columns.2.x, columns.2.y, columns.2.z,
            ]
        }
        set {
            self = .init(columns: (
                [newValue[0], newValue[1], newValue[2]],
                [newValue[3], newValue[4], newValue[5]],
                [newValue[6], newValue[7], newValue[8]]
            ))
        }
    }
}
