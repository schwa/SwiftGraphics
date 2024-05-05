// swiftlint:disable identifier_name

import CoreGraphics
import CoreGraphicsSupport

public struct Arc {
    public var center: CGPoint
    public var radius: Double
    public var theta: Double
    public var phi: Double

    public init(center: CGPoint, radius: Double, theta: Double, phi: Double) {
        self.center = center
        self.radius = radius
        self.theta = theta
        self.phi = phi
    }
}

// TODO: all geometry should be equatable/fuzzy equatable

extension Arc: Equatable {
    public static func == (lhs: Arc, rhs: Arc) -> Bool {
        lhs.center == rhs.center
            && lhs.radius == rhs.radius
            && lhs.theta == rhs.theta
            && lhs.phi == rhs.phi
    }
}

// extension Arc: FuzzyEquatable {
//    public static func ==% (lhs: Arc, rhs: Arc) -> Bool {
//        lhs.center ==% rhs.center
//            && lhs.radius ==% rhs.radius
//            && lhs.theta ==% rhs.theta
//            && lhs.phi ==% rhs.phi
//    }
// }

public extension Arc {
    static func arcToBezierCurves(center: CGPoint, radius: Double, alpha: Double, beta: Double, maximumArcs: Int = 4) -> [CubicBezierCurve] {
        assert(maximumArcs >= 3)

        let limit = Double.pi * 2 / Double(maximumArcs)

        // If[Abs[\[Beta] - \[Alpha]] > limit,
        //  		Return[{
        //    			BezierArcConstruction[{xc, yc},
        //     r, {\[Alpha], \[Alpha] + limit}],
        //    			BezierArcConstruction[{xc, yc},
        //     r, {\[Alpha] + limit, \[Beta]}]
        //    		}]
        //  	];

        if abs(beta - alpha) > (limit + .ulpOfOne) {
            // TODO: This can cause infinite recursion!
            return arcToBezierCurves(center: center, radius: radius, alpha: alpha, beta: alpha + limit, maximumArcs: maximumArcs)
                + arcToBezierCurves(center: center, radius: radius, alpha: alpha + limit, beta: beta, maximumArcs: maximumArcs)
        }

        // {x1, y1} = {xc, yc} + r*{Cos[\[Alpha]], Sin[\[Alpha]]};
        let pt1 = center + radius * CGPoint(x: cos(alpha), y: sin(alpha))
        // {x4, y4} = {xc, yc} + r*{Cos[\[Beta]], Sin[\[Beta]]};
        let pt4 = center + radius * CGPoint(x: cos(beta), y: sin(beta))
        // {ax, ay} = {x1, y1} - {xc, yc};
        let (ax, ay) = (pt1 - center).tuple
        // {bx, by} = {x4, y4} - {xc, yc};
        let (bx, by) = (pt4 - center).tuple
        // q1 = ax*ax + ay*ay;
        let q1 = ax * ax + ay * ay
        // q2 = q1 + ax*bx + ay*by;
        let q2 = q1 + ax * bx + ay * by
        // k2 = 4/3 (Sqrt[2*q1*q2] - q2)/(ax*by - ay*bx);
        var k2 = (sqrt(2 * q1 * q2) - q2) / (ax * by - ay * bx)
        k2 *= 4 / 3

        // x2 = xc + ax - k2*ay;
        // y2 = yc + ay + k2*ax;
        let pt2 = center + CGPoint(x: ax - k2 * ay, y: ay + k2 * ax)

        // x3 = xc + bx + k2*by;
        // y3 = yc + by - k2*bx;
        let pt3 = center + CGPoint(x: bx + k2 * by, y: by - k2 * bx)

        let curve = CubicBezierCurve(controlPoints: (pt1, pt2, pt3, pt4))
        return [curve]
    }

    func toBezierCurves(maximumArcs: Int = 4) -> [CubicBezierCurve] {
        Arc.arcToBezierCurves(center: center, radius: radius, alpha: phi, beta: phi + theta, maximumArcs: maximumArcs)
    }

}
