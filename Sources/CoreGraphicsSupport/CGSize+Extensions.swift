import CoreGraphics

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
        // TODO: Provide a setter
        [width, height]
    }
}

// MARK: ExpressibleByArrayLiteral


extension CGSize: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: CGFloat...) {
        self.init(elements)
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
        (width, height)
        // TODO: Provide a setter
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

    // TODO: It doesn't really make any sense to have other RNG methods on CGSize?
}
