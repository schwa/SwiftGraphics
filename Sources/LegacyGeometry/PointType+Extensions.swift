import CoreGraphics

// swiftlint:disable shorthand_operator

public extension PointType {
    static var zero: Self {
        self.init(x: Scalar(0), y: Scalar(0))
    }

    init(x: Scalar) {
        self.init(x: x, y: 0)
    }

    init(y: Scalar) {
        self.init(x: 0, y: y)
    }

    init(_ x: Scalar, _ y: Scalar) {
        self.init(x: x, y: y)
    }
}

public extension PointType {
    static func + (lhs: Self, rhs: Self) -> Self {
        Self(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        Self(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        Self(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
    }

    static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }

    static func / (lhs: Self, rhs: Self) -> Self {
        Self(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
    }

    static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }

    static prefix func - (other: Self) -> Self {
        Self(x: -other.x, y: -other.y)
    }

    static func * (lhs: Self, rhs: Scalar) -> Self {
        Self(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    static func *= (lhs: inout Self, rhs: Scalar) {
        lhs.x *= rhs
        lhs.y *= rhs
    }

    static func * (lhs: Scalar, rhs: Self) -> Self {
        Self(x: lhs * rhs.x, y: lhs * rhs.y)
    }

    static func / (lhs: Self, rhs: Scalar) -> Self {
        Self(x: lhs.x / rhs, y: lhs.y / rhs)
    }

    static func /= (lhs: inout Self, rhs: Scalar) {
        lhs.x /= rhs
        lhs.y /= rhs
    }
}

public extension PointType {
    var isZero: Bool {
        x == 0 && y == 0
    }
}

public extension PointType {
    init<Size: SizeType>(_ size: Size) where Scalar == Size.Scalar {
        self.init(x: size.width, y: size.height)
    }

    static func + <Size: SizeType>(lhs: Self, rhs: Size) -> Self where Scalar == Size.Scalar {
        Self(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
    }

    static func - <Size: SizeType>(lhs: Self, rhs: Size) -> Self where Scalar == Size.Scalar {
        Self(x: lhs.x - rhs.width, y: lhs.y - rhs.height)
    }
}

public extension SizeType {
    static func * (lhs: Self, rhs: Scalar) -> Self {
        Self(width: lhs.width * rhs, height: lhs.height * rhs)
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        Self(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
}
