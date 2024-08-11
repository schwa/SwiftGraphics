import CoreGraphics
import SwiftUI

public extension CGSize {
    init(_ width: CGFloat, _ height: CGFloat) {
        self.init(width: width, height: height)
    }
}

// MARK: To/From Arrays

public extension CGSize {
    init(_ scalars: [CGFloat]) {
        assert(scalars.count == 2)
        self.init(width: scalars[0], height: scalars[1])
    }

    var scalars: [CGFloat] {
        get {
            [width, height]
        }
        set {
            assert(newValue.count == 2)
            (self.width, self.height) = (newValue[0], newValue[1])
        }
    }
}

// MARK: Map

public extension CGSize {
    func map(_ block: (CGFloat) throws -> CGFloat) rethrows -> Self {
        try Self(block(width), block(height))
    }
}

// MARK: To/From Tuples

public extension CGSize {
    init(tuple: (CGFloat, CGFloat)) {
        self.init(width: tuple.0, height: tuple.1)
    }

    var tuple: (CGFloat, CGFloat) {
        get {
            (width, height)
        }
        set {
            (self.width, self.height) = newValue
        }
    }
}

// MARK: Math with Self types

public extension CGSize {
    static prefix func - (rhs: Self) -> Self {
        Self(-rhs.width, -rhs.width)
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        Self(lhs.width + rhs.width, lhs.height + rhs.height)
    }

    static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        Self(lhs.width - rhs.width, lhs.height - rhs.height)
    }

    static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        Self(lhs.width * rhs.width, lhs.height * rhs.height)
    }

    static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }

    static func / (lhs: Self, rhs: Self) -> Self {
        Self(lhs.width / rhs.width, lhs.height / rhs.height)
    }

    static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }

    static func * (lhs: CGFloat, rhs: Self) -> Self {
        Self(width: lhs * rhs.width, height: lhs * rhs.height)
    }
}

// MARK: Math with Scalars

public extension CGSize {
    static func * (lhs: Self, rhs: CGFloat) -> Self {
        Self(lhs.width * rhs, lhs.height * rhs)
    }

    static func *= (lhs: inout Self, rhs: CGFloat) {
        lhs = lhs * rhs
    }

    static func / (lhs: Self, rhs: CGFloat) -> Self {
        Self(lhs.width / rhs, lhs.height / rhs)
    }

    static func /= (lhs: inout Self, rhs: CGFloat) {
        lhs = lhs / rhs
    }
}

// MARK: Random

public extension CGSize {
    static func random(width: ClosedRange<CGFloat>, height: ClosedRange<CGFloat>, using generator: inout some RandomNumberGenerator) -> Self {
        Self(width: CGFloat.random(in: width, using: &generator), height: CGFloat.random(in: height, using: &generator))
    }

    static func random(width: ClosedRange<CGFloat>, height: ClosedRange<CGFloat>) -> Self {
        var rng = SystemRandomNumberGenerator()
        return random(width: width, height: height, using: &rng)
    }
}

public enum AreaOrientation {
    case square
    case landscape
    case portrait
}

public extension CGSize {
    var aspectRatio: CGFloat {
        width / height
    }

    var orientation: AreaOrientation {
        if abs(width) > abs(height) {
            .landscape
        } else if abs(width) == abs(height) {
            .square
        } else {
            .portrait
        }
    }

    func toRect() -> CGRect {
        CGRect(size: self)
    }
}

public extension CGSize {
    init(_ v: (CGFloat, CGFloat)) {
        self.init(width: v.0, height: v.1)
    }

    func toTuple() -> (CGFloat, CGFloat) {
        (width, height)
    }
}

public extension CGSize {
    var min: CGFloat {
        Swift.min(width, height)
    }

    var max: CGFloat {
        Swift.max(width, height)
    }
}

public extension CGSize {
    static func / (lhs: CGFloat, rhs: CGSize) -> CGSize {
        CGSize(width: lhs / rhs.width, height: lhs / rhs.height)
    }
}

public extension CGSize {
    init(distance d: CGFloat, angle: Angle) {
        self = CGSize(width: Darwin.cos(angle.radians) * d, height: sin(angle.radians) * d)
    }

    var angle: Angle {
        get {
            .radians(atan2(height, width))
        }
        set(v) {
            self = .init(distance: length, angle: v)
        }
    }

    var length: CGFloat {
        get {
            sqrt(lengthSquared)
        }
        set {
            self = .init(distance: newValue, angle: angle)
        }
    }

    var lengthSquared: CGFloat {
        width * width + height * height
    }
}
