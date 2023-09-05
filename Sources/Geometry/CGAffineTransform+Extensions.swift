import CoreGraphics
import CoreGraphicsSupport

// MARK: Convenience constructors.

public extension CGAffineTransform {
    init(transforms: [CGAffineTransform]) {
        var current = CGAffineTransform.identity
        for transform in transforms {
            current *= transform
        }
        self = current
    }

    // Constructor with two fingers' positions while moving fingers.
    init(from1: CGPoint, from2: CGPoint, to1: CGPoint, to2: CGPoint) {
        if from1 == from2 || to1 == to2 {
            self = CGAffineTransform.identity
        }
        else {
            let scale = to2.distance(to: to1) / from2.distance(to: from1)
            let angle1 = (to2 - to1).angle, angle2 = (from2 - from1).angle
            self = CGAffineTransform(translation: to1 - from1)
                * CGAffineTransform(scale: scale, origin: to1)
                * CGAffineTransform(rotation: angle1 - angle2, origin: to1)
        }
    }
}

// MARK: -

@available(*, deprecated, message: "Too tied to CGAffineTransform")
public protocol AffineTransformable {
    static func * (lhs: Self, rhs: CGAffineTransform) -> Self
}

@available(*, deprecated, message: "Too tied to CGAffineTransform")
public extension AffineTransformable {
    static func *= (lhs: inout Self, rhs: CGAffineTransform) {
        // swiftlint:disable:next shorthand_operator
        lhs = lhs * rhs
    }
}

@available(*, deprecated, message: "Too tied to CGAffineTransform")
extension CGPoint: AffineTransformable {
    public static func * (lhs: CGPoint, rhs: CGAffineTransform) -> CGPoint {
        lhs.applying(rhs)
    }
}

@available(*, deprecated, message: "Too tied to CGAffineTransform")
extension CGSize: AffineTransformable {
    public static func * (lhs: CGSize, rhs: CGAffineTransform) -> CGSize {
        lhs.applying(rhs)
    }
}

@available(*, deprecated, message: "Too tied to CGAffineTransform")
extension CGRect: AffineTransformable {
    public static func * (lhs: CGRect, rhs: CGAffineTransform) -> CGRect {
        lhs.applying(rhs)
    }
}
