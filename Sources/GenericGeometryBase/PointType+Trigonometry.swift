//// swiftlint:disable identifier_name
//
// import ApproximateEquality
// import CoreGraphics
// import SwiftUI
//
// public extension PointType where Scalar: BinaryFloatingPoint {
//    init(length: Scalar, angle: Scalar) {
//        self = Self(x: cos(angle) * length, y: sin(angle) * length)
//    }
//
//    var length: Scalar {
//        get {
//            sqrt(lengthSquared)
//        }
//        set(v) {
//            self = Self(length: v, angle: angle)
//        }
//    }
//
//    var lengthSquared: Scalar {
//        x * x + y * y
//    }
//
//    var angle: Scalar {
//        get {
//            atan2(y, x)
//        }
//        set(v) {
//            self = Self(length: length, angle: v)
//        }
//    }
//
//    var normalized: Self {
//        let len = length
//        return len == 0 ? self : Self(x: x / len, y: y / len)
//    }
//
//    // Returns the angle between this vector and another vector 'vec'.
//    // The result sign indicates the rotation direction from this vector to 'vec': positive for counter-clockwise, negative for clockwise.
//    func angle(to other: Self) -> Scalar { // [-M_PI, M_PI)
//        atan2(crossProduct(self, other), dotProduct(self, other))
//    }
//
//    func distance(to other: Self) -> Scalar {
//        let dx = x - other.x
//        let dy = y - other.y
//        return sqrt(dx * dx + dy * dy)
//    }
//
//    var orthogonal: Self {
//        Self(x: -y, y: x)
//    }
//
//    var transposed: Self {
//        Self(x: y, y: x)
//    }
// }
//

// MARK: -

//
// public func dotProduct<Point: PointType>(_ lhs: Point, _ rhs: Point) -> Point.Scalar {
//    lhs.x * rhs.x + lhs.y * rhs.y
// }
//
// public func crossProduct<Point: PointType>(_ lhs: Point, _ rhs: Point) -> Point.Scalar {
//    lhs.x * rhs.y - lhs.y * rhs.x
// }
//
///// https://mathworld.wolfram.com/PerpDotProduct.html
///// ⟘
///// http://geomalgorithms.com/vector_products.html#2D-Perp-Product
// TODO: Deprecate
// public func perpProduct<Point: PointType>(_ lhs: Point, _ rhs: Point) -> Point.Scalar {
//    // TODO: This looks like crossProduct
//    lhs.x * rhs.y - lhs.y * rhs.x
// }
//
///// Return true if a, b, and c all lie on the same line.
// public func collinear<T>(_ a: T, _ b: T, _ c: T, absoluteTolerance: T.Scalar.Magnitude) -> Bool where T: PointType, T.Scalar: ApproximateEquality {
//    let lhs = (b.x - a.x) * (c.y - a.y)
//    let rhs = (c.x - a.x) * (b.y - a.y)
//    return lhs.isApproximatelyEqual(to: rhs, absoluteTolerance: absoluteTolerance)
// }
//

// MARK: -

//
// private func cos<T>(_ a: T) -> T where T: BinaryFloatingPoint {
//    T(Darwin.cos(Float(a)))
// }
//
// private func sin<T>(_ a: T) -> T where T: BinaryFloatingPoint {
//    T(Darwin.sin(Float(a)))
// }
//
// private func pow<T>(_ a: T, _ b: T) -> T where T: BinaryFloatingPoint {
//    T(Darwin.pow(Float(a), Float(b)))
// }
//
// private func atan2<T>(_ a: T, _ b: T) -> T where T: BinaryFloatingPoint {
//    T(Darwin.atan2(Float(a), Float(b)))
// }
