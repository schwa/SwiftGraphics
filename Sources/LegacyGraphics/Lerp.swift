import CoreGraphics
import Foundation
import Geometry

public protocol UnitLerpable {
    static var unit: Self { get }
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
}

public protocol CompositeLerpable {
    associatedtype Factor: FloatingPoint
    static func + (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Factor, rhs: Self) -> Self
}

// MARK: -

extension CGPoint: UnitLerpable {
    public static let unit = CGPoint(x: 1, y: 1)
}

extension CGPoint: CompositeLerpable {
    public typealias Factor = CGFloat
}

extension CGSize: CompositeLerpable {
    // TODO: Move
    public static func * (lhs: CGFloat, rhs: CGSize) -> CGSize {
        Self(width: lhs * rhs.width, height: lhs * rhs.height)
    }

    public typealias Factor = CGFloat

    public static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        Self(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }

    public static func * (lhs: CGSize, rhs: CGSize) -> CGSize {
        Self(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
    }

    public static let unit = CGSize(width: 1, height: 1)
}

extension Float: UnitLerpable {
    public static var unit: Self {
        1
    }
}

extension Double: UnitLerpable {
    public static var unit: Self {
        1
    }
}

extension CGFloat: UnitLerpable {
    public static var unit: Self {
        1
    }
}

// MARK: -

extension Range where Bound: FloatingPoint {
    func lerp(by t: Bound) -> Bound {
        (1 - t) * lowerBound + t * upperBound
    }
}

public func lerp<T>(_ v: Range<T>, by t: T) -> T where T: UnitLerpable & FloatingPoint {
    lerp(from: v.lowerBound, to: v.upperBound, by: t)
}

public func lerp<T>(from v0: T, to v1: T, by t: T) -> T where T: UnitLerpable {
    (T.unit - t) * v0 + t * v1
}

public func lerp<V>(from v0: V, to v1: V, by t: V.Factor) -> V where V: CompositeLerpable {
    (1 - t) * v0 + t * v1
}

public func lerp(from v0: CGRect, to v1: CGRect, by t: CGFloat) -> CGRect {
    CGRect(
        origin: lerp(from: v0.origin, to: v1.origin, by: t),
        size: lerp(from: v0.size, to: v1.size, by: t)
    )
}

// MARK: TODO: more experiments. Get rid of "Unit" & "factor"

public protocol Lerpable {
    static func lerp(from v0: Self, to v1: Self, by t: Self) -> Self
}

extension Float: Lerpable {
    public static func lerp(from v0: Self, to v1: Self, by t: Self) -> Self {
        (1 - t) * v0 + t * v1
    }
}

public extension Lerpable where Self: UnitLerpable {
    static func lerp(from v0: Self, to v1: Self, by t: Self) -> Self {
        (unit - t) * v0 + t * v1
    }
}

// MARK: Smoothstep (https://en.wikipedia.org/wiki/Smoothstep)

public func smoothstep<T>(from edge0: T, to edge1: T, by x: T) -> T where T: FloatingPoint {
    // Scale, bias and saturate x to 0..1 range
    let x = clamp((x - edge0) / (edge1 - edge0), lower: 0, upper: 1)
    // Evaluate polynomial
    return x * x * (3 - 2 * x)
}

public func smootherstep<T>(from edge0: T, to edge1: T, by x: T) -> T where T: FloatingPoint {
    // Scale, and clamp x to 0..1 range
    let x = clamp((x - edge0) / (edge1 - edge0), lower: 0, upper: 1)
    // Evaluate polynomial
    // error: the compiler is unable to type-check this expression in reasonable time; try breaking up the expression into distinct sub-expressions
    // x * x * x * (x * (x * 6 - 15) + 10)
    let p1 = x * x * x
    let p2 = x * 6 - 15
    let p3 = (x * p2 + 10)
    return p1 * p3
}
