import CoreGraphics
import SwiftUI

extension CGPoint: @retroactive ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: CGFloat...) {
        assert(elements.count == 2)
        self.init(x: elements[0], y: elements[1])
    }
}

extension CGSize: @retroactive ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: CGFloat...) {
        assert(elements.count == 2)
        self.init(width: elements[0], height: elements[1])
    }
}

extension CGRect: @retroactive ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: CGFloat...) {
        assert(elements.count == 4)
        self = CGRect(x: elements[0], y: elements[1], width: elements[2], height: elements[3])
    }
}

extension Angle: @retroactive CustomStringConvertible {
    public var description: String {
        "\(degrees.formatted())°"
    }
}

extension Angle: @retroactive ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .init(degrees: Double(value))
    }
}

extension Angle: @retroactive ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .init(degrees: value)
    }
}

extension Angle: @retroactive AdditiveArithmetic {
    public static func + (lhs: Self, rhs: Self) -> Self {
        .init(radians: lhs.radians + rhs.radians)
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        .init(radians: lhs.radians - rhs.radians)
    }

    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    public static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }
}

extension Angle: @retroactive VectorArithmetic {
    public mutating func scale(by rhs: Double) {
        radians.scale(by: rhs)
    }

    public var magnitudeSquared: Double {
        radians.magnitudeSquared
    }
}

extension Angle: @retroactive Numeric {
}

extension Angle: @retroactive SignedNumeric {
    public init?(exactly source: some BinaryInteger) {
        self = .init(radians: Double(source))
    }

    public static prefix func - (operand: Self) -> Self {
        .radians(-operand.radians)
    }

    public static func *= (lhs: inout Self, rhs: Self) {
        lhs.radians *= rhs.radians
    }

    public var magnitude: Self {
        .init(radians: radians.magnitude)
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        .init(radians: lhs.radians * rhs.radians)
    }

    public mutating func negate() {
        self = .radians(-radians)
    }
}

extension Angle: @retroactive Strideable {
    public typealias Stride = Self

    public func distance(to other: Self) -> Self {
        Self(radians: radians - other.radians)
    }

    public func advanced(by n: Self) -> Self {
        .init(radians: radians + n.radians)
    }
}
