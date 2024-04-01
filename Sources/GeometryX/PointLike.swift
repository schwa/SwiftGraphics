import CoreGraphics
import CoreGraphicsSupport
import simd

public protocol PointLike: Equatable {
    associatedtype Scalar: SignedNumeric
    var x: Scalar { get set }
    var y: Scalar { get set }
    init(x: Scalar, y: Scalar)

    static var zero: Self { get }

    static prefix func - (lhs: Self) -> Self
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: Self) -> Self
    static func += (lhs: inout Self, rhs: Self)
    static func -= (lhs: inout Self, rhs: Self)
    static func *= (lhs: inout Self, rhs: Self)
    static func /= (lhs: inout Self, rhs: Self)

    static func * (lhs: Self, rhs: Scalar) -> Self
    static func / (lhs: Self, rhs: Scalar) -> Self
    static func * (lhs: Scalar, rhs: Self) -> Self
    static func *= (lhs: inout Self, rhs: Scalar)
    static func /= (lhs: inout Self, rhs: Scalar)

    var length: Scalar { get }
    var lengthSquared: Scalar { get }
    var normalized: Self { get }
}

public protocol PointLike3: PointLike {
    var z: Scalar { get set }
    init(x: Scalar, y: Scalar, z: Scalar)
}

extension CGPoint: PointLike {
    public var length: CGFloat {
        sqrt(lengthSquared)
    }

    public var lengthSquared: CGFloat {
        x * x + y * y
    }

    public var normalized: CGPoint {
        self / length
    }
}

extension SIMD3<Float>: PointLike, PointLike3 {
    public init(x: Scalar, y: Scalar) {
        self = [x, y, 0]
    }

    public var lengthSquared: Scalar {
        simd_length_squared(self)
    }
}
