import BaseSupport
import simd

public extension SIMD where Scalar: FloatingPoint {
    typealias Magnitude = Scalar

    func isApproximatelyEqual(to rhs: Self, absoluteTolerance: Magnitude) -> Bool {
        zip(scalars, rhs.scalars).allSatisfy { $0.isApproximatelyEqual(to: $1, absoluteTolerance: absoluteTolerance) }
    }
}

public extension simd_float3x3 {
    typealias Magnitude = Float

    func isApproximatelyEqual(to rhs: Self, absoluteTolerance: Magnitude) -> Bool {
        zip(scalars, rhs.scalars).allSatisfy { $0.isApproximatelyEqual(to: $1, absoluteTolerance: absoluteTolerance) }
    }
}

public extension simd_float4x4 {
    typealias Magnitude = Float

    func isApproximatelyEqual(to rhs: Self, absoluteTolerance: Magnitude) -> Bool {
        zip(scalars, rhs.scalars).allSatisfy { $0.isApproximatelyEqual(to: $1, absoluteTolerance: absoluteTolerance) }
    }
}
