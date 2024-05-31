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
