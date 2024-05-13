import CoreGraphics
import CoreGraphicsSupport

public struct DeCasteljauBezierCurveSampler {
    public init() {
    }

    public func sample_quadratic(curve: QuadraticBezierCurve, t: Double) -> CGPoint {
        let cp = curve.controlPoints
        let p1 = lerp(from: cp.0, to: cp.1, by: t)
        let p2 = lerp(from: cp.1, to: cp.2, by: t)
        return lerp(from: p1, to: p2, by: t)
    }

    public func sample_cubic(curve: CubicBezierCurve, t: Double) -> CGPoint {
        let cp = curve.controlPoints
        let p1 = lerp(from: cp.0, to: cp.1, by: t)
        let p2 = lerp(from: cp.1, to: cp.2, by: t)
        let p3 = lerp(from: cp.2, to: cp.3, by: t)
        let p12 = lerp(from: p1, to: p2, by: t)
        let p23 = lerp(from: p2, to: p3, by: t)
        return lerp(from: p12, to: p23, by: t)
    }

    public func sample_orderN(controlPoints: [CGPoint], t: Double) -> CGPoint {
        var points = controlPoints
        while points.count > 1 {
            points = points.windows(ofCount: 2).map { points in
                lerp(from: points.first!, to: points.last!, by: t)
            }
        }
        return points[0]
    }
}
