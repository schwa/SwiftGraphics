import CoreGraphics
import Everything

extension BezierCurve: AffineTransformable {
    public static func * (lhs: BezierCurve, rhs: CGAffineTransform) -> BezierCurve {
        let controls = lhs.controls.map {
            $0 * rhs
        }
        if let start = lhs.start {
            return BezierCurve(start: start * rhs, controls: controls, end: lhs.end * rhs)
        }
        else {
            return BezierCurve(controls: controls, end: lhs.end * rhs)
        }
    }
}
