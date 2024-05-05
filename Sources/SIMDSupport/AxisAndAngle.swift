import simd

/**
 A geometric rotation consisting of an axis and an angle around that axis
 */
public struct AxisAndAngle<Scalar> where Scalar: SIMDScalar {
    public var angle: Scalar
    public var axis: SIMD3<Scalar>
}

public extension AxisAndAngle where Scalar == Float {
    /// Create an EulerRotation from a SIMD quaternion
    init(_ r: simd_quatf) {
        angle = r.angle
        axis = r.axis
    }
}

public extension simd_quatf {
    /// Create a SIMD quarternion from a EulerRotation
    init(_ r: AxisAndAngle<Float>) {
        self = simd_quatf(angle: r.angle, axis: r.axis)
    }
}
