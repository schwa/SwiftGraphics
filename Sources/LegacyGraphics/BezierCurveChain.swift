import CoreGraphics
import CoreGraphicsSupport
import SwiftUI

public struct BezierCurveChain {
    // TODO: This isn't really an accurate representaiton of what we want.
    // TODO: Control points should be shared (and mirrored) between neighbouring curves.
    public let curves: [BezierCurve]
    public let closed: Bool

    public init(curves: [BezierCurve], closed: Bool = false) {
        var previousCurve: BezierCurve?
        self.curves = curves.map { (curve: BezierCurve) -> BezierCurve in
            var newCurve = curve
            if let previousEndPoint = previousCurve?.end, let start = curve.start {
                assert(previousEndPoint == start)
                newCurve = BezierCurve(controls: curve.controls, end: curve.end)
            }

            previousCurve = curve
            return newCurve
        }

        self.closed = closed
    }
}

extension BezierCurveChain: CustomStringConvertible {
    public var description: String {
        curves.map { String(describing: $0) }.joined(separator: ", ")
    }
}

extension BezierCurveChain: AffineTransformable {
    public func applying(_ transform: CGAffineTransform) -> BezierCurveChain {
        let transformedCurves = curves.map {
            $0.applying(transform)
        }
        return BezierCurveChain(curves: transformedCurves)
    }
}

public extension BezierCurveChain {
    func toPath() -> Path {
        var path = Path()

        guard let start = curves[0].start else {
            fatalError("Unimplemented")
        }
        path.move(to: start)
        for curve in curves {
            path.add(curve: curve)
        }

        if closed {
            path.closeSubpath()
        }

        return path
    }
}
