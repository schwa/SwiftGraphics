import Foundation
import simd
import SIMDSupport

extension Angle: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .init(radians: Value(value))
    }
}

extension Angle: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .init(radians: Value(value))
    }
}

extension Angle: AdditiveArithmetic {
    public static func + (lhs: Self, rhs: Self) -> Self {
        .init(radians: lhs.radians + rhs.radians)
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        .init(radians: lhs.radians - rhs.radians)
    }
}

extension Angle: SignedNumeric {
    public static func *= (lhs: inout Self, rhs: Self) {
        lhs.radians *= rhs.radians
    }

    public init?(exactly source: some BinaryInteger) {
        self = .init(radians: Value(source))
    }

    public var magnitude: Self {
        .init(radians: radians.magnitude)
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        .init(radians: lhs.radians * rhs.radians)
    }
}

extension Angle: Strideable {
    public typealias Stride = Self

    public func distance(to other: Self) -> Self {
        Self(radians: radians - other.radians)
    }

    public func advanced(by n: Self) -> Self {
        .init(radians: radians + n.radians)
    }
}
