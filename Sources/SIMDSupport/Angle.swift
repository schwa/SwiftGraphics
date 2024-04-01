import Foundation
import simd

/**
 A geometric angle whose value you access in either radians or degrees.
 */
public struct Angle<Value>: Equatable, Hashable, Comparable where Value: BinaryFloatingPoint {
    public var radians: Value

    /**
     ```swift doctest
     Angle(radians: 0.0).degrees // => 0.0
     ```
     */
    public var degrees: Value {
        get {
            radiansToDegrees(radians)
        }
        set {
            radians = degreesToRadians(newValue)
        }
    }

    public init(radians: Value) {
        self.radians = radians
    }

    /**
     ```swift doctest
     Angle(degrees: 0.0).degrees // => 0.0
     Angle(degrees: 360.0).radians // => .pi * 2
     ```
     */
    public init(degrees: Value) {
        radians = degreesToRadians(degrees)
    }

    public static func radians(_ radians: Value) -> Angle {
        Angle(radians: radians)
    }

    public static func degrees(_ degrees: Value) -> Angle {
        Angle(degrees: degrees)
    }

    public static func < (lhs: Angle<Value>, rhs: Angle<Value>) -> Bool {
        lhs.radians < rhs.radians
    }
}

// MARK: -

extension Angle: Sendable where Value: Sendable {
}

// MARK: -

extension Angle: Codable where Value: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        radians = try container.decode(Value.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(radians)
    }
}

// MARK: -

public extension Angle {
    /**
     Angle between the vector and the Z axis.
     ```swift doctest
     Angle(x: 1, y: 1).degrees // => 45
     ```
     */
    init(x: Value, y: Value) {
        self = .init(radians: atan2(y, x))
    }
}

public extension Angle where Value: SIMDScalar {
    init(_ vector: SIMD2<Value>) {
        self = .init(radians: atan2(vector.y, vector.x))
    }

    init(from: SIMD2<Value>, to: SIMD2<Value>) {
        self = .init(to - from)
    }
}

public extension simd_quatf {
    init(angle: Angle<Float>, axis: SIMD3<Float>) {
        self = simd_quatf(angle: angle.radians, axis: axis)
    }
}

public extension Angle where Value.RawSignificand: FixedWidthInteger {
    static func randomDegrees(in range: ClosedRange<Value>) -> Angle {
        let value = Value.random(in: range)
        return Angle.degrees(value)
    }
}

public extension SIMD2 where Scalar: BinaryFloatingPoint {
    init(length: Scalar, angle: Angle<Scalar>) {
        self = SIMD2(cos(angle.radians) * length, sin(angle.radians))
    }
}

// MARK: -

public struct AngleFormatStyle<Value>: FormatStyle where Value: BinaryFloatingPoint {
    public init() {}

    public func format(_ value: Angle<Value>) -> String {
        let degrees = FloatingPointFormatStyle().precision(.fractionLength(1)).format(value.degrees)
        return "\(degrees)°"
    }
}

public extension FormatStyle where Self == AngleFormatStyle<Float>, FormatInput == SIMDSupport.Angle<Float> {
    static var degrees: Self {
        AngleFormatStyle<Float>()
    }
}

public extension FormatStyle where Self == AngleFormatStyle<Double>, FormatInput == SIMDSupport.Angle<Double> {
    static var degrees: Self {
        AngleFormatStyle<Double>()
    }
}
