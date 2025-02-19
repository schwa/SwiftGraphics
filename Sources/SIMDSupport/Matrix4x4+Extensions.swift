import Foundation
import simd
import SwiftUI

public extension simd_float4x4 {
    @inlinable init(scale s: SIMD3<Float>) {
        self = simd_float4x4(columns: (
            [s.x, 0, 0, 0],
            [0, s.y, 0, 0],
            [0, 0, s.z, 0],
            [0, 0, 0, 1]
        ))
    }

    @inlinable init(translate t: SIMD3<Float>) {
        self = simd_float4x4(columns: (
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [t.x, t.y, t.z, 1]
        ))
    }

    @inlinable init(rotationAngle angle: Angle, axis: SIMD3<Float>) {
        let quat = simd_quaternion(Float(angle.radians), axis)
        self = simd_float4x4(quat)
    }

    @inlinable static func scaled(_ s: SIMD3<Float>) -> simd_float4x4 {
        simd_float4x4(scale: s)
    }

    @inlinable static func translation(_ t: SIMD3<Float>) -> simd_float4x4 {
        simd_float4x4(translate: t)
    }

    @inlinable static func rotation(angle: Angle, axis: SIMD3<Float>) -> simd_float4x4 {
        simd_float4x4(simd_quaternion(Float(angle.radians), axis))
    }
}

public extension simd_float4x4 {
    @inlinable init(_ m: simd_float3x3) {
        self = simd_float4x4(columns: (
            SIMD4<Float>(m.columns.0, 0),
            SIMD4<Float>(m.columns.1, 0),
            SIMD4<Float>(m.columns.2, 0),
            [0, 0, 0, 1]
        ))
    }
}

// MARK: Rows

public extension simd_float4x4 {
    // swiftlint:disable:next large_tuple
    @inlinable init(rows: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)) {
        self = simd_float4x4(columns: rows).transpose
    }

    var rows: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>) {
        (row(0), row(1), row(2), row(3))
    }

    private func row(_ row: Int) -> SIMD4<Float> { [
        self[0, row],
        self[1, row],
        self[2, row],
        self[3, row]
    ] }

    @inlinable var diagonal: SIMD4<Float> {
        SIMD4<Float>([self[0, 0], self[1, 1], self[2, 2], self[3, 3]])
    }
}

// MARK: Cells

public extension simd_float4x4 {
    @inlinable init(scalars: [Scalar]) {
        self = .identity
        self.scalars = scalars
    }

    @inlinable var scalars: [Scalar] {
        get {
            [
                columns.0.x, columns.0.y, columns.0.z, columns.0.w,
                columns.1.x, columns.1.y, columns.1.z, columns.1.w,
                columns.2.x, columns.2.y, columns.2.z, columns.2.w,
                columns.3.x, columns.3.y, columns.3.z, columns.3.w
            ]
        }
        set {
            self = .init(columns:
                            (simd_float4(newValue[0], newValue[1], newValue[2], newValue[3]),
                             simd_float4(newValue[4], newValue[5], newValue[6], newValue[7]),
                             simd_float4(newValue[8], newValue[9], newValue[10], newValue[11]),
                             simd_float4(newValue[12], newValue[13], newValue[14], newValue[15]))
            )
        }
    }
}

// MARK: More

public extension simd_float4x4 {
    @inlinable static func * (lhs: simd_float4x4, rhs: simd_quatf) -> simd_float4x4 {
        lhs * simd_float4x4(rhs)
    }

    @inlinable static func * (lhs: simd_quatf, rhs: simd_float4x4) -> simd_float4x4 {
        simd_float4x4(lhs) * rhs
    }
}

public extension simd_float4x4 {
    @inlinable func map<R>(_ f: (SIMD4<Float>) throws -> R) rethrows -> [R] {
        try [columns.0, columns.1, columns.2, columns.3].map(f)
    }
}
