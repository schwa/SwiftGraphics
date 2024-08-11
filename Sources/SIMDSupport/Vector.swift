import simd

public extension SIMD2 where Scalar == Float {
    static let unit = SIMD2<Scalar>(1, 1)

    var length: Scalar {
        simd_length(self)
    }

    var normalized: SIMD2<Scalar> {
        simd.normalize(self)
    }
}

public extension SIMD2 where Scalar == Double {
    static let unit = SIMD2<Scalar>(1, 1)

    var length: Scalar {
        simd_length(self)
    }

    var normalized: SIMD2<Scalar> {
        simd.normalize(self)
    }
}

// MARK: -

public extension SIMD3 where Scalar == Float {
    static let unit = SIMD3<Scalar>(1, 1, 1)

    var length: Scalar {
        simd_length(self)
    }

    var normalized: SIMD3<Scalar> {
        simd.normalize(self)
    }
}

public extension SIMD3 where Scalar == Double {
    static let unit = SIMD3<Scalar>(1, 1, 1)

    var length: Scalar {
        simd_length(self)
    }

    var normalized: SIMD3<Scalar> {
        simd.normalize(self)
    }
}

// MARK: -

public extension SIMD4 where Scalar == Float {
    static let unit = SIMD4<Scalar>(1, 1, 1, 1)

    var length: Scalar {
        simd_length(self)
    }

    var normalized: SIMD4<Scalar> {
        simd.normalize(self)
    }
}

// MARK: -

public extension SIMD4 where Scalar == Double {
    static let unit = SIMD4<Scalar>(1, 1, 1, 1)

    var length: Scalar {
        simd_length(self)
    }

    var normalized: SIMD4<Scalar> {
        simd.normalize(self)
    }
}

// MARK: -

public extension SIMD {
    var scalars: [Scalar] {
        (0 ..< scalarCount).map { self[$0] }
    }
}

public extension SIMD3 {
    func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Scalar) throws -> Result) rethrows -> Result {
        var result = initialResult
        result = try nextPartialResult(result, x)
        result = try nextPartialResult(result, y)
        result = try nextPartialResult(result, z)
        return result
    }
}

public extension SIMD {
    func map<R>(_ f: (Scalar) throws -> R) rethrows -> [R] {
        try (0 ..< scalarCount).map { try f(self[$0]) }
    }
}

public extension SIMD4 {
    var r: Scalar {
        get { x }
        set { x = newValue }
    }

    var g: Scalar {
        get { y }
        set { y = newValue }
    }

    var b: Scalar {
        get { z }
        set { z = newValue }
    }

    var a: Scalar {
        get { w }
        set { w = newValue }
    }
}

// MARK: -

public extension SIMD3 where Scalar == Float {
    func cross(_ other: Self) -> Self {
        simd_cross(self, other)
    }
}

public extension SIMD2 where Scalar: FloatingPoint {
    /** Returns twice the signed area of the triangle determined by a,b,c. The area is positive if a,b,c are oriented ccw, negative if cw, and zero if the points are collinear. */
    static func area2(_ a: Self, _ b: Self, _ c: Self) -> Scalar {
        let t1 = (b.x - a.x) * (c.y - a.y)
        let t2 = (c.x - a.x) * (b.y - a.y)
        return t1 - t2
    }

    /** Returns true iff c is strictly to the left of the directed line through a to b. */
    static func left(_ a: Self, _ b: Self, _ c: Self) -> Bool {
        area2(a, b, c) > 0
    }

    static func leftOn(_ a: Self, _ b: Self, _ c: Self) -> Bool {
        area2(a, b, c) >= 0
    }

    static func collinear(_ a: Self, _ b: Self, _ c: Self) -> Bool {
        area2(a, b, c) == 0
    }

    /** Returns true iff ab properly intersects cd: they share a point interior to both segments. The properness of the intersection is ensured by using strict leftness. */
    static func intersectProp(_ a: Self, _ b: Self, _ c: Self, _ d: Self) -> Bool {
        func xor(_ x: Bool, _ y: Bool) -> Bool {
            switch (x, y) {
            case (true, false), (false, true):
                true
            default:
                false
            }
        }
        if collinear(a, b, c) || collinear(a, b, d) || collinear(c, d, a) || collinear(c, d, b) {
            return false
        } else {
            return xor(left(a, b, c), left(a, b, d))
                && xor(left(c, d, c), left(c, d, b))
        }
    }

    /** Returns TRUE iff point c lies on the closed segement ab. First checks that c is collinear with a and b. */
    static func between(_ a: Self, _ b: Self, _ c: Self) -> Bool {
        if !collinear(a, b, c) {
            return false
        }
        if a.x != b.x {
            return ((a.x <= c.x) && (c.x <= b.x)) || ((a.x >= c.x) && (c.x >= b.x))
        } else {
            return ((a.y <= c.y) && (c.y <= b.y)) || ((a.y >= c.y) && (c.y >= b.y))
        }
    }

    /** Returns TRUE iff segments ab and cd intersect, properly or improperly. */
    static func intersect(_ a: Self, _ b: Self, _ c: Self, _ d: Self) -> Bool {
        if intersectProp(a, b, c, d) {
            true
        } else if between(a, b, c) || between(a, b, d) || between(c, d, a) || between(c, d, b) {
            true
        } else {
            false
        }
    }
}

// MARK: -

public extension SIMD3 where Scalar: BinaryFloatingPoint, Scalar.RawSignificand: FixedWidthInteger {
    static func random(in range: ClosedRange<Scalar>) -> SIMD3<Scalar> {
        let r: () -> Scalar = { Scalar.random(in: range) }
        return SIMD3<Scalar>(r(), r(), r())
    }
}
