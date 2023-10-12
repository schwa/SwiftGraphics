// swiftlint:disable identifier_name

import CoreGraphics
import Geometry

// MARK: Regular Polygon

// TODO: Does not seem to work with _star_ style polygons (e.g. can be convex)

public struct RegularPolygon {
    public let nside: Int
    public let center: CGPoint
    public let vertex: CGPoint
    public var radius: CGFloat { center.distance(to: vertex) }
    public var startAngle: CGFloat { (vertex - center).angle }

    public init(nside: Int, center: CGPoint, vertex: CGPoint) {
        self.nside = nside
        self.center = center
        self.vertex = vertex
    }

    public init(nside: Int, center: CGPoint, radius: CGFloat) {
        self.init(nside: nside, center: center, vertex: center + CGPoint(x: radius, y: 0))
    }

    public init(nside: Int, center: CGPoint, radius: CGFloat, startAngle: CGFloat) {
        self.init(nside: nside, center: center, vertex: center + CGPoint(length: radius, angle: startAngle))
    }
}

public extension RegularPolygon {
    var isDegenerate: Bool { nside < 3 || isFuzzyEqual(center, vertex) }

    var centralAngle: CGFloat { CGFloat(2 * .pi / Double(nside)) }
    var interiorAngle: CGFloat { CGFloat(Double(nside - 2) * .pi / Double(nside)) }
    var exteriorAngle: CGFloat { centralAngle }

    var area: CGFloat { CGFloat(pow(radius, 2) * sin(centralAngle) * CGFloat(nside) / 2) }
    var length: CGFloat { sideLength * CGFloat(nside) }
    var sideLength: CGFloat { CGFloat(2 * radius * sin(centralAngle / 2)) }

    var inradius: CGFloat { radius * cos(centralAngle / 2) }
    var circumRadius: CGFloat { radius }

    var circumcircle: Circle { Circle(center: center, radius: radius) }
    var incircle: Circle { Circle(center: center, radius: inradius) }

    var points: [CGPoint] {
        let s = startAngle, c = centralAngle, r = radius
        return (0 ..< nside).map { self.center + CGPoint(length: r, angle: s + c * CGFloat($0)) }
    }
}

// MARK: Applying transform

public extension RegularPolygon {
    static func * (lhs: RegularPolygon, rhs: CGAffineTransform) -> RegularPolygon {
        RegularPolygon(nside: lhs.nside, center: lhs.center * rhs, vertex: lhs.vertex * rhs)
    }
}

// MARK: Convenience initializers

public extension RegularPolygon {
    // ! Construct with center and two adjacent vertexes.
    // The adjacent vertex is approximately on the ray from center to the first vertex.
    init(center: CGPoint, vertex: CGPoint, adjacent: CGPoint) {
        let angle = (adjacent - center).angle(to: vertex - center)
        let nside = (angle == 0) ? 3 : max(3, Int(round(.pi / angle)))
        self.init(nside: nside, center: center, vertex: vertex)
    }
}

// MARK: Move vertexes

// TODO:

public extension RegularPolygon {
    // Returns new polygon whose vertex moved to the specified location.
    func pointMoved(v: (Int, CGPoint)) -> RegularPolygon {
        if v.0 >= 0 && v.0 < nside {
            let angle = (v.1 - center).angle - centralAngle * CGFloat(v.0)
            return RegularPolygon(nside: nside, center: center, radius: radius, startAngle: angle)
        }
        return self * CGAffineTransform(translation: v.1 - center)
    }

    /// Returns new polygon whose two adjacent vertexes moved to the specified locations.
    func twoPointsMoved(v1: (Int, CGPoint), _ v2: (Int, CGPoint)) -> RegularPolygon {
        func isBeside(i1: Int, i2: Int) -> Bool {
            i1 >= 0 && i1 < i2 && i2 < nside && (i1 == i2 - 1 || (i1 == 0 && i2 == nside - 1))
        }
        if isBeside(i1: min(v1.0, v2.0), i2: max(v1.0, v2.0)) && !isFuzzyEqual(v1.1, v2.1) {
            let xf = CGAffineTransform(from1: points[v1.0], from2: points[v2.0], to1: v1.1, to2: v2.1)
            return self * xf
        }
        return self
    }
}
