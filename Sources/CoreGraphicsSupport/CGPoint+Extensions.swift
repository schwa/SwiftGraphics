import Foundation
import SwiftUI

public extension CGPoint {
    init(_ x: CGFloat, _ y: CGFloat) {
        self.init(x: x, y: y)
    }

    var isZero: Bool {
        self == .zero
    }
}

public extension CGPoint {
    init(_ scalars: [CGFloat]) {
        assert(scalars.count == 2)
        self.init(x: scalars[0], y: scalars[1])
    }

    var scalars: [CGFloat] {
        get {
            [x, y]
        }
        set {
            assert(newValue.count == 2)
            self.x = newValue[0]
            self.y = newValue[1]
        }
    }
}

public extension CGPoint {
    func map(_ f: (CGFloat) -> CGFloat) -> CGPoint {
        CGPoint(x: f(x), y: f(y))
    }
}

@available(*, deprecated, message: "Deprecated.")
public extension CGPoint {
    init(tuple: (CGFloat, CGFloat)) {
        self.init(x: tuple.0, y: tuple.1)
    }

    var tuple: (CGFloat, CGFloat) {
        get {
            (x, y)
        }
        set {
            (self.x, self.y) = newValue
        }
    }
}

public extension CGPoint {
    static prefix func - (rhs: Self) -> Self {
        .init(-rhs.x, -rhs.y)
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        Self(lhs.x + rhs.x, lhs.y + rhs.y)
    }

    static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        .init(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        .init(lhs.x * rhs.x, lhs.y * rhs.y)
    }

    static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }

    static func / (lhs: Self, rhs: Self) -> Self {
        .init(lhs.x / rhs.x, lhs.y / rhs.y)
    }

    static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }
}

public extension CGPoint {
    static func * (lhs: Self, rhs: CGFloat) -> Self {
        .init(lhs.x * rhs, lhs.y * rhs)
    }

    static func *= (lhs: inout Self, rhs: CGFloat) {
        lhs = lhs * rhs
    }

    static func / (lhs: Self, rhs: CGFloat) -> Self {
        .init(lhs.x / rhs, lhs.y / rhs)
    }

    static func /= (lhs: inout Self, rhs: CGFloat) {
        lhs = lhs / rhs
    }

    static func * (lhs: CGFloat, rhs: Self) -> Self {
        .init(lhs * rhs.x, lhs * rhs.y)
    }
}

// MARK: Random.

public extension CGPoint {
    static func random(x: ClosedRange<CGFloat>, y: ClosedRange<CGFloat>, using generator: inout some RandomNumberGenerator) -> Self {
        .init(x: CGFloat.random(in: x, using: &generator), y: CGFloat.random(in: y, using: &generator))
    }

    static func random(x: ClosedRange<CGFloat>, y: ClosedRange<CGFloat>) -> Self {
        var rng = SystemRandomNumberGenerator()
        return random(x: x, y: y, using: &rng)
    }

    static func random(using generator: inout some RandomNumberGenerator) -> Self {
        random(x: 0 ... 1, y: 0 ... 1, using: &generator)
    }

    static func random() -> Self {
        var rng = SystemRandomNumberGenerator()
        return Self.random(using: &rng)
    }

    static func random(in rect: CGRect, using generator: inout some RandomNumberGenerator) -> Self {
        random(x: rect.minX ... rect.maxX, y: rect.minY ... rect.maxY, using: &generator)
    }

    static func random(in rect: CGRect) -> Self {
        var rng = SystemRandomNumberGenerator()
        return Self.random(in: rect, using: &rng)
    }
}

// MARK: Misc

public extension CGPoint {
    var length: CGFloat {
        get {
            sqrt(lengthSquared)
        }
        set {
            self = .init(length: newValue, angle: angle)
        }
    }

    var lengthSquared: CGFloat {
        x * x + y * y
    }

    @available(*, deprecated, message: "Use lengthSquared")
    var magnitude: CGFloat {
        lengthSquared
    }

    func distance(to other: Self) -> CGFloat {
        Self.distance(self, other)
    }

    static func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        (rhs - lhs).length
    }

    var normalized: Self {
        isZero ? self : self / length
    }

    var transposed: Self {
        .init(x: y, y: x)
    }

    var perpendicular: Self {
        .init(x: -y, y: x)
    }

    init(origin: CGPoint = .zero, length d: CGFloat, angle: Angle) {
        self = CGPoint(x: origin.x + Darwin.cos(angle.radians) * d, y: origin.y + sin(angle.radians) * d)
    }

    var angle: Angle {
        get {
            .init(to: self)
        }
        set {
            self = .init(length: length, angle: newValue)
        }
    }
}

/// The dot product of two vectors is the sum of the products of the corresponding components of the two vectors.
public func dotProduct(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
    lhs.x * rhs.x + lhs.y * rhs.y
}

/// The sign of the 2D cross product tells you whether the second vector is on the left or right side of the first vector (the direction of the first vector being front). The absolute value of the 2D cross product is the sine of the angle in between the two vectors, so taking the arc sine of it would give you the angle in radians.
public func crossProduct(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
    lhs.x * rhs.y - lhs.y * rhs.x
}

public extension CGPoint {
    func flipVertically(within rect: CGRect) -> CGPoint {
        CGPoint(x: x, y: rect.height - y)
    }
}
