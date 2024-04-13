import Foundation
import SwiftUI

public extension CGPoint {
    init(_ x: CGFloat, _ y: CGFloat) {
        self.init(x: x, y: y)
    }
}

public extension CGPoint {
    init(_ scalars: [CGFloat]) {
        assert(scalars.count == 2)
        self.init(x: scalars[0], y: scalars[1])
    }

    var scalars: [CGFloat] {
        // TODO: Provide a setter
        [x, y]
    }
}


public extension CGPoint {
    func map(_ f: (CGFloat) -> CGFloat) -> CGPoint {
        CGPoint(x: f(x), y: f(y))
    }
}

public extension CGPoint {
    var length: CGFloat {
        get {
            sqrt(lengthSquared)
        }
        set {
            self = .init(distance: newValue, angle: angle)
        }
    }

    var lengthSquared: CGFloat {
        x * x + y * y
    }
}

extension CGPoint: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: CGFloat...) {
        self.init(elements)
    }
}

public extension CGPoint {
    func map(_ block: (CGFloat) throws -> CGFloat) rethrows -> Self {
        try Self(block(x), block(y))
    }
}

public extension CGPoint {
    init(tuple: (CGFloat, CGFloat)) {
        self.init(x: tuple.0, y: tuple.1)
    }

    var tuple: (CGFloat, CGFloat) {
        (x, y)
        // TODO: Provide a setter
    }
}

public extension CGPoint {
    static prefix func - (rhs: Self) -> Self {
        Self(-rhs.x, -rhs.y)
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        Self(lhs.x + rhs.x, lhs.y + rhs.y)
    }

    static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        Self(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        Self(lhs.x * rhs.x, lhs.y * rhs.y)
    }

    static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }

    static func / (lhs: Self, rhs: Self) -> Self {
        Self(lhs.x / rhs.x, lhs.y / rhs.y)
    }

    static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }
}

public extension CGPoint {
    static func * (lhs: Self, rhs: CGFloat) -> Self {
        Self(lhs.x * rhs, lhs.y * rhs)
    }

    static func *= (lhs: inout Self, rhs: CGFloat) {
        lhs = lhs * rhs
    }

    static func / (lhs: Self, rhs: CGFloat) -> Self {
        Self(lhs.x / rhs, lhs.y / rhs)
    }

    static func /= (lhs: inout Self, rhs: CGFloat) {
        lhs = lhs / rhs
    }

    static func * (lhs: CGFloat, rhs: Self) -> Self {
        Self(lhs * rhs.x, lhs * rhs.y)
    }
}

// MARK: Random.

public extension CGPoint {
    static func random(x: ClosedRange<CGFloat>, y: ClosedRange<CGFloat>, using generator: inout some RandomNumberGenerator) -> Self {
        Self(x: CGFloat.random(in: x, using: &generator), y: CGFloat.random(in: y, using: &generator))
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
    var magnitude: CGFloat {
        x * x + y * y
    }

    var distance: CGFloat {
        sqrt(magnitude)
    }

    func distance(to other: Self) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }

    static func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        let d = rhs - lhs
        return sqrt(d.x * d.x + d.y * d.y)
    }

    var normalized: Self {
        let len = length
        return len == 0 ? self : Self(x: x / len, y: y / len)
    }

    var orthogonal: Self {
        Self(x: -y, y: x)
    }

    var transposed: Self {
        Self(x: y, y: x)
    }

    init(origin: CGPoint = .zero, distance d: CGFloat, angle: Angle) {
        self = CGPoint(x: origin.x + Darwin.cos(angle.radians) * d, y: origin.y + sin(angle.radians) * d)
    }

    var angle: Angle {
        get {
            .radians(atan2(y, x))
        }
        set(v) {
            self = .init(distance: distance, angle: v)
        }
    }

    // Returns the angle between this vector and another vector 'vec'.
    // The result sign indicates the rotation direction from this vector to 'vec': positive for counter-clockwise, negative for clockwise.
    // TODO: Unit test
    func angle(to other: Self) -> CGFloat { // [-M_PI, M_PI)
        atan2(crossProduct(self, other), dotProduct(self, other))
    }

    // TODO: Unit test
    static func angle(_ lhs: CGPoint, _ rhs: CGPoint) -> Angle {
        let d = rhs - lhs
        return d.angle
    }

}

// TODO: Misc 2

// ﬁnd a projection of a vector over anotlqer vector ﬁnd work done by a force
public func dotProduct(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
    lhs.x * rhs.x + lhs.y * rhs.y
}

// swiftlint:disable:next line_length
/// The sign of the 2D cross product tells you whether the second vector is on the left or right side of the first vector (the direction of the first vector being front). The absolute value of the 2D cross product is the sine of the angle in between the two vectors, so taking the arc sine of it would give you the angle in radians.
public func crossProduct(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
    lhs.x * rhs.y - lhs.y * rhs.x
}

// TODO: Deprecation zone

/// Return the angle between vertex-p1 and vertex-vertex.x
//@available(*, deprecated, message: "Do not use")
public func angle(_ vertex: CGPoint, _ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
    let a = (p1 - vertex).angle(to: p2 - vertex)
    return a.magnitude
}

public extension CGPoint {
    func flipVertically(within rect: CGRect) -> CGPoint {
        CGPoint(x: x, y: rect.height - y)
    }
}

