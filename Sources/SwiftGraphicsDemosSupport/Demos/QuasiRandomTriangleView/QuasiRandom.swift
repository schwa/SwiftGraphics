import Foundation
import SwiftUI
import Shapes2D

// https://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/
func quasiRandomPointIn(size: CGSize, n: Int) -> CGPoint {
    let n = Double(n)
    let g = 1.32471795724474602596
    let a1 = 1.0 / g
    let a2 = 1.0 / (g * g)
    let x = (0.5 + a1 * n).truncatingRemainder(dividingBy: 1)
    let y = (0.5 + a2 * n).truncatingRemainder(dividingBy: 1)
    return CGPoint(x: x * size.width, y: y * size.height)
}

func quasiRandomPointIn(triangle: Triangle, n: Int) -> CGPoint {
    let point = quasiRandomPointIn(size: CGSize(width: 1, height: 1), n: n)
    return pointInTriangle(point: UnitPoint(x: point.x, y: point.y), triangle: triangle)
}

extension Triangle {

    var a: CGPoint {
        get {
            vertices.0
        }
        set {
            vertices.0 = newValue
        }
    }

    var b: CGPoint {
        get {
            vertices.1
        }
        set {
            vertices.1 = newValue
        }
    }

    var c: CGPoint {
        get {
            vertices.2
        }
        set {
            vertices.2 = newValue
        }
    }

    init(a: CGPoint, b: CGPoint, c: CGPoint) {
        self.init(a, b, c)
    }

    var area: Double {
        Swift.abs((a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y)) / 2.0)
    }

    func contains(point: CGPoint) -> Bool {
        func sign(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGFloat {
            return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
        }
        let d1 = sign(p1: point, p2: a, p3: b)
        let d2 = sign(p1: point, p2: b, p3: c)
        let d3 = sign(p1: point, p2: c, p3: a)
        let hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0)
        let hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0)
        return !(hasNeg && hasPos)
    }
}

/// Calculates the corresponding point in the triangle or reflects it if it's outside the triangle.
///
/// Given a `UnitPoint` with coordinates (x, y) where both x and y are values between 0 and 1, representing the fractional distances along the edges of the triangle from vertex `a` to `b` and from vertex `a` to `c` respectively, this function calculates the corresponding point within the triangle. If the point lies outside the triangle, it reflects the point over the line segment from `b` to `c`.
///
/// The function effectively considers the parallelogram formed by the vertices of the triangle and a reflection of the triangle's first vertex, and the mirror image of `a` across the line segment from `b` to `c`. If the calculated point lies in the part of the parallelogram outside the triangle, it is reflected back into the triangle.
///
/// - Parameters:
///   - point: The unit point with values between 0 and 1.
///   - triangle: The triangle with vertices `a`, `b`, and `c`.
/// - Returns: The calculated point in the coordinate space of the triangle or the reflected point if outside the triangle.
func pointInTriangle(point: UnitPoint, triangle: Triangle) -> CGPoint {
    let ab = point.x
    let ac = point.y
    // Calculate the point based on m and n
    let parallelogramPoint = CGPoint(x: (1 - ab - ac) * triangle.a.x + ab * triangle.b.x + ac * triangle.c.x,
                        y: (1 - ab - ac) * triangle.a.y + ab * triangle.b.y + ac * triangle.c.y)

    // Check if the point is inside the triangle
    if ab + ac <= 1 {
        return parallelogramPoint
    } else {
        // Reflect the point over the line b->c
        let midpoint = CGPoint(x: (triangle.b.x + triangle.c.x) / 2, y: (triangle.b.y + triangle.c.y) / 2)
        return CGPoint(x: midpoint.x - (parallelogramPoint.x - midpoint.x), y: midpoint.y - (parallelogramPoint.y - midpoint.y))
    }
}

struct Parallelogram {
    var triangle: Triangle
    var opposite: CGPoint

    init(triangle: Triangle) {
        self.triangle = triangle
        self.opposite = CGPoint(x: triangle.a.x + (triangle.c.x - triangle.b.x), y: triangle.a.y + (triangle.c.y - triangle.b.y))
    }

    func reflectedPoint(from point: CGPoint) -> CGPoint {
        let acSegment = LineSegment(triangle.a, triangle.c)
        let midpoint = acSegment.midpoint
        return CGPoint(x: midpoint.x - (point.x - midpoint.x), y: midpoint.y - (point.y - midpoint.y))
    }
}

extension LineSegment {
    var midpoint: CGPoint {
        CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
    }
}
