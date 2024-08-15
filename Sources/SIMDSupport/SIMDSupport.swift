import CoreGraphicsSupport
import simd
import SwiftUI

public struct DecodingError: Error {}

public extension SIMD3 where Scalar == Float {
    func dot(_ other: Self) -> Float {
        simd_dot(self, other)
    }
}

public extension SIMD2<Float> {
    init(length: Float, angle: Angle) {
        self = .init(x: cos(Float(angle.radians)) * length, y: sin(Float(angle.radians)) * length)
    }
}

public extension SIMD3 where Scalar: BinaryFloatingPoint {
    init(xy: SIMD2<Scalar>) {
        self = SIMD3(xy[0], xy[1], 0)
    }
}

public extension CGColor {
    var simd: SIMD4<Float> {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            fatalError("Could not create color space sRGB.")
        }
        guard let converted = converted(to: colorSpace, intent: .defaultIntent, options: nil) else {
            fatalError("Could not convert color to colour space.")
        }
        guard let components = converted.components?.map({ Float($0) }) else {
            fatalError("Could not get components.")
        }
        return .init(components)
    }
}

public extension RollPitchYaw {
    func isApproximatelyEqual(to other: Self, absoluteTolerance: Angle) -> Bool {
        roll.isApproximatelyEqual(to: other.roll, absoluteTolerance: absoluteTolerance)
            && pitch.isApproximatelyEqual(to: other.pitch, absoluteTolerance: absoluteTolerance)
            && yaw.isApproximatelyEqual(to: other.yaw, absoluteTolerance: absoluteTolerance)
    }
}

public extension SIMD4 where Scalar == Float {
    func clamped(to range: ClosedRange<Scalar>) -> Self {
        [x.clamped(to: range), y.clamped(to: range), z.clamped(to: range), w.clamped(to: range)]
    }
}
