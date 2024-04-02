import CoreGraphics
import Foundation

public protocol ScalarType: Comparable, SignedNumeric {
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: Self) -> Self

    static func += (lhs: inout Self, rhs: Self)
    static func -= (lhs: inout Self, rhs: Self)
    static func *= (lhs: inout Self, rhs: Self)
    static func /= (lhs: inout Self, rhs: Self)

    init(_ value: Int)
    init(_ value: Double)
}

// MARK: -

public protocol PointType: Equatable {
    associatedtype Scalar: ScalarType

    var x: Scalar { get set }
    var y: Scalar { get set }

    init(x: Scalar, y: Scalar)
}

// MARK: -

public protocol SizeType: Equatable {
    associatedtype Scalar: ScalarType

    var width: Scalar { get set }
    var height: Scalar { get set }

    init(width: Scalar, height: Scalar)
}

public protocol RectType: Equatable {
    associatedtype Scalar: ScalarType
    associatedtype Point: PointType /* where Point.Scalar == Scalar */
    associatedtype Size: SizeType

    var origin: Point { get set }
    var size: Size { get set }

    init(origin: Point, size: Size)
}

// MARK: -

extension Float: ScalarType {
}

extension Double: ScalarType {
}

extension CGFloat: ScalarType {
}

extension CGPoint: PointType {
}

extension CGSize: SizeType {
}

extension CGRect: RectType {
    public typealias Scalar = CGFloat
}
