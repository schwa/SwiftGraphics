// swiftlint:disable identifier_name

import ApproximateEquality
import CoreGraphics
import CoreGraphicsSupport
import SwiftUI

public struct Triangle {
    public var vertices: (CGPoint, CGPoint, CGPoint)

    public init(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint) {
        vertices = (p0, p1, p2)
    }
}

public extension Triangle {
    /// Convenience initializer creating trangle from points in a rect. p0 is top middle, p1 and p2 are bottom left and bottom right
    init(rect: CGRect, rotation: Angle = .zero) {
        var p0 = rect.midXMinY
        var p1 = rect.minXMaxY
        var p2 = rect.maxXMaxY

        if rotation != .zero {
            let mid = rect.mid
            let transform = CGAffineTransform.rotation(rotation, origin: mid)
            p0 = p0.applying(transform)
            p1 = p1.applying(transform)
            p2 = p2.applying(transform)
        }

        vertices = (p0, p1, p2)
    }
}

public extension Triangle {
    init(points: [CGPoint]) {
        assert(points.count == 3)
        vertices = (points[0], points[1], points[2])
    }

    var points: [CGPoint] {
        [vertices.0, vertices.1, vertices.2]
    }
}

// TODO: This is a hack
func isFuzzyEqual(_ lhs: CGFloat, _ rhs: CGFloat) -> Bool {
    lhs.isApproximatelyEqual(to: rhs, absoluteTolerance: 0.0001)
}

public extension Triangle {
    var lengths: (Double, Double, Double) {
        (
            (vertices.0 - vertices.1).length,
            (vertices.1 - vertices.2).length,
            (vertices.2 - vertices.0).length
        )
    }

    // TODO:
    var angles: (Angle, Angle, Angle) {
        let a1 = Angle(vertex: vertices.0, p1: vertices.1, p2: vertices.2)
        let a2 = Angle(vertex: vertices.1, p1: vertices.2, p2: vertices.0)
        let a3 = .degrees(180) - a1 - a2
        return (a1, a2, a3)
    }

    var isEquilateral: Bool {
        equalities(lengths) { isFuzzyEqual($0, $1) } == 3
    }

    var isIsosceles: Bool {
        equalities(lengths) { isFuzzyEqual($0, $1) } == 2
    }

    var isScalene: Bool {
        equalities(lengths) { isFuzzyEqual($0, $1) } == 1
    }

    var isRightAngled: Bool {
        let a = angles
        let rightAngle = 0.5 * .pi
        return isFuzzyEqual(a.0.radians, rightAngle) || isFuzzyEqual(a.1.radians, rightAngle) || isFuzzyEqual(a.2.radians, rightAngle)
    }

    var isOblique: Bool {
        isRightAngled == false
    }

    var isAcute: Bool {
        let a = angles
        let rightAngle = 0.5 * .pi
        return a.0.radians < rightAngle && a.1.radians < rightAngle && a.2.radians < rightAngle
    }

    var isObtuse: Bool {
        let a = angles
        let rightAngle = 0.5 * .pi
        return a.0.radians > rightAngle || a.1.radians > rightAngle || a.2.radians > rightAngle
    }

    var isDegenerate: Bool {
        let a = angles
        let r180 = Double.pi
        return isFuzzyEqual(a.0.radians, r180) || isFuzzyEqual(a.1.radians, r180) || isFuzzyEqual(a.2.radians, r180)
    }

    var signedArea: Double {
        let (a, b, c) = vertices
        let signedArea = 0.5 * (
            a.x * (b.y - c.y) +
                b.x * (c.y - a.y) +
                c.x * (a.y - b.y)
        )
        return signedArea
    }

    var area: Double { abs(signedArea) }

    // https: //en.wikipedia.org/wiki/Circumscribed_circle
    var circumcenter: CGPoint {
        let (a, b, c) = vertices

        let D = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))

        let a2 = pow(a.x, 2) + pow(a.y, 2)
        let b2 = pow(b.x, 2) + pow(b.y, 2)
        let c2 = pow(c.x, 2) + pow(c.y, 2)

        let X = (a2 * (b.y - c.y) + b2 * (c.y - a.y) + c2 * (a.y - b.y)) / D
        let Y = (a2 * (c.x - b.x) + b2 * (a.x - c.x) + c2 * (b.x - a.x)) / D

        return CGPoint(x: X, y: Y)
    }

    var circumcircle: Circle {
        let (a, b, c) = lengths
        let diameter = (a * b * c) / (2 * area)
        return Circle(center: circumcenter, diameter: diameter)
    }

    var incenter: CGPoint {
        let (oppositeC, oppositeA, oppositeB) = lengths
        let x = (oppositeA * vertices.0.x + oppositeB * vertices.1.x + oppositeC * vertices.2.x) / (oppositeC + oppositeB + oppositeA)
        let y = (oppositeA * vertices.0.y + oppositeB * vertices.1.y + oppositeC * vertices.2.y) / (oppositeC + oppositeB + oppositeA)

        return CGPoint(x: x, y: y)
    }

    var inradius: Double {
        let (a, b, c) = lengths
        return 2 * area / (a + b + c)
    }

    var incircle: Circle {
        Circle(center: incenter, radius: inradius)
    }
}

//// Cartesian coordinates
public extension Triangle {
    // TODO:
    // converts trilinear coordinates to Cartesian coordinates relative
    // to the incenter; thus, the incenter has coordinates (0.0, 0.0)
    func toLocalCartesian(alpha: Double, beta: Double, gamma: Double) -> CGPoint {
        let area = area
        let (a, b, c) = lengths

        let r = 2 * area / (a + b + c)
        let k = 2 * area / (a * alpha + b * beta + c * gamma)
        let C = angles.2.radians

        let x = (k * beta - r + (k * alpha - r) * cos(C)) / sin(C)
        let y = k * alpha - r

        return CGPoint(x: x, y: y)
    }

    // TODO: This seems broken! --- validate that this is still needed..
    func toCartesian(alpha: Double, beta: Double, gamma: Double) -> CGPoint {
        let a = toLocalCartesian(alpha: alpha, beta: beta, gamma: gamma)
        let delta = toLocalCartesian(alpha: 0, beta: 0, gamma: 1)
        return vertices.0 + a - delta
    }
}

// MARK: Utilities

func equalities<T>(_ e: (T, T, T), test: (T, T) -> Bool) -> Int {
    var c = 1
    if test(e.0, e.1) {
        c += 1
    }
    if test(e.1, e.2) {
        c += 1
    }
    if test(e.2, e.0) {
        c += 1
    }
    return min(c, 3)
}
