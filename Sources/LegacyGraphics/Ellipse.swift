// swiftlint:disable identifier_name

import CoreGraphics
import Geometry

public struct Ellipse {
    public let center: CGPoint
    public let a: CGFloat // Semi major axis
    public let b: CGFloat // Semi minor axis
    public let e: CGFloat // Eccentricity
    public let F: CGFloat // Distance to foci
    public let rotation: CGFloat

    public init(center: CGPoint, semiMajorAxis a: CGFloat, eccentricity e: CGFloat, rotation: CGFloat = 0.0) {
        assert(a >= 0)
        assert(e >= 0 && e <= 1)

        self.center = center
        self.a = a
        b = a * sqrt(1.0 - e * e)
        self.e = e
        F = a * e
        self.rotation = rotation
    }

    public init(center: CGPoint, semiMajorAxis a: CGFloat, semiMinorAxis b: CGFloat, rotation: CGFloat = 0.0) {
        assert(a >= b)
        assert(a >= 0)

        self.center = center
        self.a = a
        self.b = b
        e = sqrt(1 - pow(b / a, 2))
        F = a * e
        self.rotation = rotation
    }

    public var foci: (CGPoint, CGPoint) {
        let t = CGAffineTransform(rotationAngle: rotation)
        return (
            center + CGPoint(x: -F, y: 0) * t,
            center + CGPoint(x: +F, y: 0) * t
        )
    }
}

extension Ellipse: CustomStringConvertible {
    public var description: String {
        "Ellipse(center: \(center), semiMajorAxis: \(a) semiMinorAxis: \(b), eccentricity: \(e), rotation: \(rotation)"
    }
}

public extension Ellipse {
    init(center: CGPoint, size: CGSize, rotation: CGFloat = 0.0) {
        let semiMajorAxis: CGFloat = max(size.width, size.height) * 0.5
        let semiMinorAxis: CGFloat = min(size.width, size.height) * 0.5

        var rotation = rotation
        if size.height > size.width {
            rotation += degreesToRadians(90)
        }

        self.init(center: center, semiMajorAxis: semiMajorAxis, semiMinorAxis: semiMinorAxis, rotation: rotation)
    }

    init(frame: CGRect) {
        self.init(center: frame.mid, size: frame.size, rotation: 0.0)
    }

    /// CGSize of ellipse if rotation were 0
    var unrotatedSize: CGSize {
        CGSize(width: a * 2, height: b * 2)
    }

    /// Frame of ellipse if rotation were 0. This is generally not very useful. See boundingBox.
    var unrotatedFrame: CGRect {
        let size = unrotatedSize
        let origin = CGPoint(x: center.x - size.width * 0.5, y: center.y - size.height * 0.5)
        return CGRect(origin: origin, size: size)
    }

    // TODO: FIXME
//    var boundingBox: CGRect {
//        let bezierCurves = toBezierCurves()
//        let rects = [
//            bezierCurves.0.boundingBox,
//            bezierCurves.1.boundingBox,
//            bezierCurves.2.boundingBox,
//            bezierCurves.3.boundingBox
//            ]
//
//        return CGRect.unionOfRects(rects)
//    }
}

public extension Ellipse {
    func toCircle() -> Circle? {
        if e == 0.0 {
            assert(a == b)
            assert(F == 0.0)
            return Circle(center: center, radius: a)
        }
        else {
            return nil
        }
    }
}

// TODO:

public extension Ellipse {
    func toBezierChain() -> BezierCurveChain {
        let curves = toBezierCurves()
        let curvesArray = [curves.0, curves.1, curves.2, curves.3]
        return BezierCurveChain(curves: curvesArray, closed: true)
    }

    // From http: //spencermortensen.com/articles/bezier-circle/ (via @iamdavidhart)
    static let c: CGFloat = 0.551_915_024_494

    func toBezierCurves(c: CGFloat = Ellipse.c) -> (BezierCurve, BezierCurve, BezierCurve, BezierCurve) {
        let t = CGAffineTransform(rotation: rotation)

        let da = a * c
        let db = b * c
        let curve0 = BezierCurve(
            start: center + CGPoint(x: 0, y: b) * t,
            control1: center + (CGPoint(x: 0, y: b) + CGPoint(x: da, y: 0)) * t,
            control2: center + (CGPoint(x: a, y: 0) + CGPoint(x: 0, y: db)) * t,
            end: center + CGPoint(x: a, y: 0) * t
        )
        let curve1 = BezierCurve(
            start: center + CGPoint(x: a, y: 0) * t,
            control1: center + (CGPoint(x: a, y: 0) + CGPoint(x: 0, y: -db)) * t,
            control2: center + (CGPoint(x: 0, y: -b) + CGPoint(x: da, y: 0)) * t,
            end: center + CGPoint(x: 0, y: -b) * t
        )
        let curve2 = BezierCurve(
            start: center + CGPoint(x: 0, y: -b) * t,
            control1: center + (CGPoint(x: 0, y: -b) + CGPoint(x: -da, y: 0)) * t,
            control2: center + (CGPoint(x: -a, y: 0) + CGPoint(x: 0, y: -db)) * t,
            end: center + CGPoint(x: -a, y: 0) * t
        )
        let curve3 = BezierCurve(
            start: center + CGPoint(x: -a, y: 0) * t,
            control1: center + (CGPoint(x: -a, y: 0) + CGPoint(x: 0, y: db)) * t,
            control2: center + (CGPoint(x: 0, y: b) + CGPoint(x: -da, y: 0)) * t,
            end: center + CGPoint(x: 0, y: b) * t
        )

        return (curve0, curve1, curve2, curve3)
    }
}
