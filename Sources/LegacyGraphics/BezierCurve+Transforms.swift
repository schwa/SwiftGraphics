import CoreGraphics
import CoreGraphicsSupport

extension BezierCurve: AffineTransformable {
    public func applying(_ transform: CGAffineTransform) -> Self {
        let controls = controls.map {
            $0.applying(transform)
        }
        if let start = start {
            return BezierCurve(start: start.applying(transform), controls: controls, end: end.applying(transform))
        }
        else {
            return BezierCurve(controls: controls, end: end.applying(transform))
        }
    }
}
