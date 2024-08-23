import CoreGraphics
import CoreGraphicsSupport
import SwiftUI

// swiftlint:disable force_unwrapping

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
        return 0.5 * (
            a.x * (b.y - c.y) +
                b.x * (c.y - a.y) +
                c.x * (a.y - b.y)
        )
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

public extension Triangle {
    // Convert Cartesian coordinates to trilinear coordinates
    func toTrilinear(_ point: CGPoint) -> (Double, Double, Double) {
        let (a, b, c) = sideDistances()
        let (area1, area2, area3) = subtrianglesAreas(point)
        let totalArea = area

        return (
            Double(area1) * 2 / (a * Double(totalArea)),
            Double(area2) * 2 / (b * Double(totalArea)),
            Double(area3) * 2 / (c * Double(totalArea))
        )
    }

    // Convert trilinear coordinates to Cartesian coordinates
    func toCartesian(_ trilinear: (Double, Double, Double)) -> CGPoint {
        let (x1, y1) = (vertices.0.x, vertices.0.y)
        let (x2, y2) = (vertices.1.x, vertices.1.y)
        let (x3, y3) = (vertices.2.x, vertices.2.y)
        let (a, b, c) = trilinear

        let denominator = a + b + c
        let x = CGFloat((a * x1 + b * x2 + c * x3) / denominator)
        let y = CGFloat((a * y1 + b * y2 + c * y3) / denominator)

        return CGPoint(x: x, y: y)
    }

    // Clamp a point to the closest point within the triangle
    func clamp(_ point: CGPoint) -> CGPoint {
        // Check if the point is inside the triangle
        if isPointInside(point) {
            return point
        }

        // Find the closest point on each edge
        let closestOnEdge1 = closestPointOnLineSegment(point, lineStart: vertices.0, lineEnd: vertices.1)
        let closestOnEdge2 = closestPointOnLineSegment(point, lineStart: vertices.1, lineEnd: vertices.2)
        let closestOnEdge3 = closestPointOnLineSegment(point, lineStart: vertices.2, lineEnd: vertices.0)

        // Find the closest among these three points
        let distances = [
            point.distance(to: closestOnEdge1),
            point.distance(to: closestOnEdge2),
            point.distance(to: closestOnEdge3)
        ]

        let minDistance = distances.min()!
        if minDistance == distances[0] {
            return closestOnEdge1
        } else if minDistance == distances[1] {
            return closestOnEdge2
        } else {
            return closestOnEdge3
        }
    }

    // Helper function to check if a point is inside the triangle
    func isPointInside(_ point: CGPoint) -> Bool {
        let (area1, area2, area3) = subtrianglesAreas(point)
        let totalArea = area

        // The point is inside if the sum of subtriangle areas equals the total area
        // We use a small epsilon for floating-point comparison
        let epsilon: CGFloat = 1e-6
        return abs(area1 + area2 + area3 - totalArea) < epsilon
    }

    // Helper function to find the closest point on a line segment
    func closestPointOnLineSegment(_ point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGPoint {
        let lineVector = CGPoint(x: lineEnd.x - lineStart.x, y: lineEnd.y - lineStart.y)
        let pointVector = CGPoint(x: point.x - lineStart.x, y: point.y - lineStart.y)

        let lineLengthSquared = lineVector.x * lineVector.x + lineVector.y * lineVector.y
        let t = max(0, min(1, (pointVector.x * lineVector.x + pointVector.y * lineVector.y) / lineLengthSquared))

        return CGPoint(
            x: lineStart.x + t * lineVector.x,
            y: lineStart.y + t * lineVector.y
        )
    }

    // Helper function to calculate side lengths
    private func sideDistances() -> (Double, Double, Double) {
        let a = vertices.1.distance(to: vertices.2)
        let b = vertices.2.distance(to: vertices.0)
        let c = vertices.0.distance(to: vertices.1)
        return (a, b, c)
    }

    // Helper function to calculate areas of subtriangles
    private func subtrianglesAreas(_ point: CGPoint) -> (CGFloat, CGFloat, CGFloat) {
        let area1 = Triangle(point, vertices.1, vertices.2).area
        let area2 = Triangle(vertices.0, point, vertices.2).area
        let area3 = Triangle(vertices.0, vertices.1, point).area
        return (area1, area2, area3)
    }

    //    // Helper function to calculate the area of the triangle
    //    func area() -> CGFloat {
    //        let (x1, y1) = (vertices.0.x, vertices.0.y)
    //        let (x2, y2) = (vertices.1.x, vertices.1.y)
    //        let (x3, y3) = (vertices.2.x, vertices.2.y)
    //        return abs((x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)) / 2)
    //    }
}
