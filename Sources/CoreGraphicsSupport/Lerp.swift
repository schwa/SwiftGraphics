import CoreGraphics

// MARK: Lerpable

public protocol Lerpable {
    associatedtype Factor
    static func lerp(from v0: Self, to v1: Self, by t: Factor) -> Self
}

public extension Lerpable where Self: FloatingPoint {
    static func lerp(from v0: Self, to v1: Self, by t: Self) -> Self {
        (1 - t) * v0 + t * v1
    }
}

// MARK: -

public extension Lerpable where Self: UnitLerpable {
    static func lerp(from v0: Self, to v1: Self, by t: Self) -> Self {
        (unit - t) * v0 + t * v1
    }
}

// MARK: UnitLerpable

public protocol UnitLerpable: Lerpable {
    static var unit: Self { get }
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
}

extension CGPoint: UnitLerpable {
    public static let unit = CGPoint(x: 1, y: 1)
}

// MARK: CompositeLerpable

public protocol CompositeLerpable: Lerpable {
    // associatedtype Factor: FloatingPoint
    static func + (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Factor, rhs: Self) -> Self
}

public extension Lerpable where Self: CompositeLerpable, Self.Factor: FloatingPoint {
    static func lerp(from v0: Self, to v1: Self, by t: Factor) -> Self {
        (1 - t) * v0 + t * v1
    }
}

extension CGPoint: CompositeLerpable {
    public typealias Factor = CGFloat
}

extension CGSize: CompositeLerpable {
    public typealias Factor = CGFloat

    // TODO: Move

    public static let unit = CGSize(width: 1, height: 1)
}

// MARK: -

extension Range where Bound: FloatingPoint {
    func lerp(by t: Bound) -> Bound {
        (1 - t) * lowerBound + t * upperBound
    }
}

// MARK: Junk

public func lerp<T>(_ v: Range<T>, by t: T.Factor) -> T where T: UnitLerpable & FloatingPoint {
    lerp(from: v.lowerBound, to: v.upperBound, by: t)
}

public func lerp<T>(from v0: T, to v1: T, by t: T.Factor) -> T where T: Lerpable {
    T.lerp(from: v0, to: v1, by: t)
}

// public func lerp<T>(from v0: T, to v1: T, by t: T) -> T where T: UnitLerpable {
//    T.lerp(from: v0, to: v1, by: t)
// }

// @available(*, deprecated, message: "Use static lerp")
// public func lerp<V>(from v0: V, to v1: V, by t: V.Factor) -> V where V: CompositeLerpable, V.Factor: FloatingPoint {
//    (1 - t) * v0 + t * v1
// }
//
// @available(*, deprecated, message: "Use static lerp")
// public func lerp(from v0: CGRect, to v1: CGRect, by t: CGFloat) -> CGRect {
//    CGRect(
//        origin: lerp(from: v0.origin, to: v1.origin, by: t),
//        size: lerp(from: v0.size, to: v1.size, by: t)
//    )
// }

// @available(*, deprecated, message: "Use static lerp")
// public func lerp(from: CGPoint, to: CGPoint, by t: CGFloat) -> CGPoint {
//    ((1.0 - t) * from) + (t * to)
// }
//
