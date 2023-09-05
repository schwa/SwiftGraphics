// swiftlint:disable identifier_name

// MARK: Circle

import CoreGraphics
import Geometry

public struct Circle {
    public let center: CGPoint
    public let radius: CGFloat

    public init(center: CGPoint = CGPoint.zero, radius: CGFloat) {
        self.center = center
        self.radius = radius
    }
}

// MARK: -

public extension Circle {
    var diameter: CGFloat {
        radius * 2
    }

    init(center: CGPoint = CGPoint.zero, diameter: CGFloat) {
        self.center = center
        radius = diameter * 0.5
    }
}

// MARK: -

/// Create a Circle from any three non-colinear points
public extension Circle {
    init(points: (CGPoint, CGPoint, CGPoint)) throws {
        // https://en.wikipedia.org/wiki/Circumscribed_circle#Cartesian_coordinates_2
        let b = points.1 - points.0
        let c = points.2 - points.0
        let d = 2 * (b.x * c.y - b.y * c.x)
        guard d != 0 else {
            // throw Error.generic("Points are colinear")
            fatalError("Unimplemented")
        }
        let bms = b.lengthSquared
        let cms = c.lengthSquared
        let ux = (c.y * bms - b.y * cms) / d
        let uy = (b.x * cms - c.x * bms) / d
        let center = CGPoint(x: ux, y: uy)
        let r = center.length
        self = Circle(center: center + points.0, radius: r)
    }
}

// MARK: -

public extension Circle {
    func toEllipse() -> Ellipse {
        Ellipse(center: center, size: CGSize(width: diameter, height: diameter))
    }

    func toBezierChain() -> BezierCurveChain {
        toEllipse().toBezierChain()
    }
}
