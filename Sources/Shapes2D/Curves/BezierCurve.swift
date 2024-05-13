import CoreGraphics
import CoreGraphicsSupport

// import Algorithms

// https://pomax.github.io/bezierinfo/
// https://www.youtube.com/watch?v=aVwxzDHniEw
// https://www.youtube.com/watch?v=jvPPXbo87ds

public struct QuadraticBezierCurve {
    public var controlPoints: (CGPoint, CGPoint, CGPoint)

    public init(controlPoints: (CGPoint, CGPoint, CGPoint)) {
        self.controlPoints = controlPoints
    }
}

public extension QuadraticBezierCurve {
    init(controlPoints: [CGPoint]) {
        assert(controlPoints.count == 3)
        self.controlPoints = (controlPoints[0], controlPoints[1], controlPoints[2])
    }
}

// MARK: -

public struct CubicBezierCurve {
    public var controlPoints: (CGPoint, CGPoint, CGPoint, CGPoint)

    public init(controlPoints: (CGPoint, CGPoint, CGPoint, CGPoint)) {
        self.controlPoints = controlPoints
    }
}

public extension CubicBezierCurve {
    init(controlPoints: [CGPoint]) {
        assert(controlPoints.count == 4)
        self.controlPoints = (controlPoints[0], controlPoints[1], controlPoints[2], controlPoints[3])
    }
}

public extension CubicBezierCurve {
    init(curve: QuadraticBezierCurve) {
        controlPoints = (
            curve.controlPoints.0,
            curve.controlPoints.0 + (2.0 / 3.0 * (curve.controlPoints.1 - curve.controlPoints.0)),
            curve.controlPoints.2 + (2.0 / 3.0 * (curve.controlPoints.1 - curve.controlPoints.2)),
            curve.controlPoints.2
        )
    }
}

// MARK: -

public extension CubicBezierCurve {
    func render() -> [CGPoint] {
        let cpX: (Double, Double, Double, Double) = (controlPoints.0.x, controlPoints.1.x, controlPoints.2.x, controlPoints.3.x)
        let xSolver = BernsteinPolynomalCubicCurveSolver(controlPoints: cpX)
        let cpY: (Double, Double, Double, Double) = (controlPoints.0.y, controlPoints.1.y, controlPoints.2.y, controlPoints.3.y)
        let ySolver = BernsteinPolynomalCubicCurveSolver(controlPoints: cpY)
        return stride(from: 0, through: 1, by: 1.0 / 48.0).map { t in
            let x = xSolver.sample_cubic_matrix(t: t)
            let y = ySolver.sample_cubic_matrix(t: t)
            return CGPoint(x: x, y: y)
        }
    }
}
