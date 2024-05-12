import simd
import SwiftUI

func degreesToRadians<F>(_ value: F) -> F where F: FloatingPoint {
    value * .pi / 180
}

func radiansToDegrees<F>(_ value: F) -> F where F: FloatingPoint {
    value * 180 / .pi
}

public struct DecodingError: Error {}

// TODO: Move
public extension SIMD3 where Scalar == Float {
    func dot(_ other: Self) -> Float {
        simd_dot(self, other)
    }
}

// TODO: Move
public extension SIMD2<Float> {
    init(length: Float, angle: Angle) {
        self = .init(x: cos(Float(angle.radians)) * length, y: sin(Float(angle.radians)) * length)
    }
}

// TODO: Move
public extension SIMD3 where Scalar: BinaryFloatingPoint {
    init(xy: SIMD2<Scalar>) {
        self = SIMD3(xy[0], xy[1], 0)
    }
}
