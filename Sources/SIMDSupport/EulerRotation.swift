import simd

/**
 A geometric rotation consisting of an axis and an angle around that axis
 */
// @available(*, deprecated, message: "Will be renamed to angle & axis")
public struct EulerRotation<Scalar> where Scalar: SIMDScalar {
    public var angle: Scalar
    public var axis: SIMD3<Scalar>
}

public extension EulerRotation where Scalar == Float {
    /// Create an EulerRotation from a SIMD quaternion
    init(_ r: simd_quatf) {
        angle = r.angle
        axis = r.axis
    }
}

public extension simd_quatf {
    /// Create a SIMD quarternion from a EulerRotation
    init(_ r: EulerRotation<Float>) {
        self = simd_quatf(angle: r.angle, axis: r.axis)
    }
}
