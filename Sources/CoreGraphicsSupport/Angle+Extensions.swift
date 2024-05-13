import Foundation
import SwiftUI

// We treat SwiftUI.Angle as part of CoreGraphics - because it's too useful not to be.

public extension Angle {
    init(to point: CGPoint) {
        self = Angle(radians: CoreGraphics.atan2(point.y, point.x))
    }

    init(from lhs: CGPoint, to rhs: CGPoint) {
        self = Angle(radians: CoreGraphics.atan2(rhs.y - lhs.y, rhs.x - lhs.x))
    }

    init(vertex: CGPoint, p1: CGPoint, p2: CGPoint) {
        self = Angle(from: p1, to: vertex) - Angle(from: p2, to: vertex)
    }

    static func atan2(y: CGFloat, x: CGFloat) -> Angle {
        .init(radians: CoreGraphics.atan2(y, x))
    }
}

// MARK: Angle unsafe conformances.

extension Angle: CustomStringConvertible {
    public var description: String {
        "\(degrees.formatted())°"
    }
}

extension Angle: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .init(degrees: Double(value))
    }
}

extension Angle: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .init(degrees: value)
    }
}

extension Angle: AdditiveArithmetic {
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

extension Angle: SignedNumeric {
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

extension Angle: Strideable {
    public typealias Stride = Self

    public func distance(to other: Self) -> Self {
        Self(radians: radians - other.radians)
    }

    public func advanced(by n: Self) -> Self {
        .init(radians: radians + n.radians)
    }
}

public extension Angle {
    static func / (lhs: Self, rhs: Self) -> Self {
        .init(radians: lhs.radians / rhs.radians)
    }

    static func /= (lhs: inout Self, rhs: Self) {
        lhs.radians /= rhs.radians
    }

    func truncatingRemainder(dividingBy d: Self) -> Self {
        .radians(radians.truncatingRemainder(dividingBy: d.radians))
    }
}

// MARK: -

func abs(_ value: Angle) -> Angle {
    .radians(Swift.abs(value.radians))
}
