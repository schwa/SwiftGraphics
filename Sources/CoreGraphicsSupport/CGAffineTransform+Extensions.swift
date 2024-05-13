import CoreGraphics
import SwiftUI

public extension CGAffineTransform {
    static func * (lhs: CGAffineTransform, rhs: CGAffineTransform) -> CGAffineTransform {
        lhs.concatenating(rhs)
    }

    static func *= (lhs: inout CGAffineTransform, rhs: CGAffineTransform) {
        lhs = lhs.concatenating(rhs)
    }
}

public extension CGAffineTransform {
    init() {
        self = CGAffineTransform.identity
    }
}

public extension CGAffineTransform {
    static func translation(_ translation: CGPoint) -> Self {
        CGAffineTransform(translationX: translation.x, y: translation.y)
    }

    static func translation(_ translation: CGSize) -> Self {
        CGAffineTransform(translationX: translation.width, y: translation.height)
    }

    static func translation(_ translation: CGVector) -> Self {
        CGAffineTransform(translationX: translation.dx, y: translation.dy)
    }

    static func translation(x: Double, y: Double) -> Self {
        CGAffineTransform(translationX: x, y: y)
    }

    static func translation(x: Double) -> Self {
        CGAffineTransform(translationX: x, y: 0)
    }

    static func translation(y: Double) -> Self {
        CGAffineTransform(translationX: 0, y: y)
    }

    // MARK: -

    static func scale(_ scale: CGPoint) -> Self {
        CGAffineTransform(scaleX: scale.x, y: scale.y)
    }

    static func scale(_ scale: CGSize) -> Self {
        CGAffineTransform(scaleX: scale.width, y: scale.height)
    }

    static func scale(_ scale: CGVector) -> Self {
        CGAffineTransform(scaleX: scale.dx, y: scale.dy)
    }

    static func scale(x: Double, y: Double) -> Self {
        CGAffineTransform(scaleX: x, y: y)
    }

    static func scale(_ value: Double) -> Self {
        CGAffineTransform(scaleX: value, y: value)
    }

    static func scale(_ value: Double, origin: CGPoint) -> Self {
        .translation(x: -origin.x, y: -origin.y) * CGAffineTransform(scaleX: value, y: value) * .translation(x: origin.x, y: origin.y)
    }

    static func scale(x: Double, y: Double, origin: CGPoint) -> Self {
        .translation(x: -origin.x, y: -origin.y) * CGAffineTransform(scaleX: x, y: y) * .translation(x: origin.x, y: origin.y)
    }

    // MARK: -

    static func rotation(_ angle: Angle) -> Self {
        CGAffineTransform(rotationAngle: angle.radians)
    }

    static func rotation(_ angle: Angle, origin: CGPoint) -> Self {
        .translation(x: -origin.x, y: -origin.y) * CGAffineTransform(rotationAngle: angle.radians) * .translation(x: origin.x, y: origin.y)
    }
}

// MARK: Converting transforms to/from arrays

public extension CGAffineTransform {
    init(_ values: [CGFloat]) {
        assert(values.count == 6)
        self = CGAffineTransform(a: values[0], b: values[1], c: values[2], d: values[3], tx: values[4], ty: values[5])
    }

    var values: [CGFloat] {
        get {
            [a, b, c, d, tx, ty]
        }
        set(v) {
            assert(v.count == 6)
            (a, b, c, d, tx, ty) = (v[0], v[1], v[2], v[3], v[4], v[6])
        }
    }
}

// MARK: Convenience constructors.

public extension CGAffineTransform {
    init(transforms: [CGAffineTransform]) {
        var current = CGAffineTransform.identity
        for transform in transforms {
            current = current.concatenating(transform)
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
            self = .translation(to1 - from1)
                * .scale(scale, origin: to1)
                * .rotation(angle1 - angle2, origin: to1)
        }
    }
}

// MARK: -

public protocol AffineTransformable {
    func applying(_ transform: CGAffineTransform) -> Self
}

