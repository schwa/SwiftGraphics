// swiftlint:disable identifier_name

import CoreGraphics
import SwiftUI
import Everything

public struct BezierCurve {
    public enum Order {
        case quadratic
        case cubic
        case orderN(Int)
    }

    public var start: CGPoint?
    public var controls: [CGPoint]
    public var end: CGPoint

    public init(controls: [CGPoint], end: CGPoint) {
        self.controls = controls
        self.end = end
    }

    public init(start: CGPoint, controls: [CGPoint], end: CGPoint) {
        self.start = start
        self.controls = controls
        self.end = end
    }

    public var order: Order {
        switch controls.count + 2 {
        case 3:
            return .quadratic
        case 4:
            return .cubic
        default:
            return .orderN(controls.count + 2)
        }
    }

    public var points: [CGPoint] {
        if let start {
            return [start] + controls + [end]
        }
        else {
            return controls + [end]
        }
    }
}

// MARK: Convenience initializers

public extension BezierCurve {
    init(control1: CGPoint, end: CGPoint) {
        controls = [control1]
        self.end = end
    }

    init(control1: CGPoint, control2: CGPoint, end: CGPoint) {
        controls = [control1, control2]
        self.end = end
    }

    init(start: CGPoint, control1: CGPoint, end: CGPoint) {
        self.start = start
        controls = [control1]
        self.end = end
    }

    init(start: CGPoint, control1: CGPoint, control2: CGPoint, end: CGPoint) {
        self.start = start
        controls = [control1, control2]
        self.end = end
    }

    init(points: [CGPoint]) {
        start = points[0]
        controls = Array(points[1 ..< points.count - 1])
        end = points[points.count - 1]
    }

    init(start: CGPoint, end: CGPoint) {
        self.start = start
        controls = [(start + end) / 2]
        self.end = end
    }
}

// MARK: Increasing the order.

public extension BezierCurve {
    func increasedOrder() -> BezierCurve {
        switch controls.count {
        case 1:
            let CP1 = points[0] + (CGPoint.Factor(2.0 / 3.0) * (points[1] - points[0]))
            let CP2 = points[2] + (CGPoint.Factor(2.0 / 3.0) * (points[1] - points[2]))
            return BezierCurve(start: start!, controls: [CP1, CP2], end: end)
        case 2:
            return self
        default:
            return BezierCurve(start: start!, end: end).increasedOrder()
        }
    }
}

// MARK: Converting from tuples

// MARK: Stroking the path to a context

// TODO: Move into own file

// public extension CGContextRef {
//
//    func addToPath(curve: BezierCurve) {
//        switch curve.order {
//            case .Quadratic:
//                CGContextAddQuadCurveToPoint(self, curve.controls[0].x, curve.controls[0].y, curve.end.x, curve.end.y)
//            case .Cubic:
//                CGContextAddCurveToPoint(self, curve.controls[0].x, curve.controls[0].y, curve.controls[1].x, curve.controls[1].y, curve.end.x, curve.end.y)
//            case .OrderN:
//                assert(false)
//        }
//    }
//
//    func stroke(curve: BezierCurve) {
//        if let start = curve.start {
//            CGContextMoveToPoint(self, start.x, start.y)
//        }
//        addToPath(curve)
//        CGContextStrokePath(self)
//    }
// }

extension Path {
        @discardableResult
        mutating func add(curve: BezierCurve) -> Path {
            switch curve.order {
            case .cubic:
                addCurve(to: curve.end, control1: curve.controls[0], control2: curve.controls[1])
            case .quadratic:
                addQuadCurve(to: curve.end, control: curve.controls[0])
            default:
                assertionFailure("Unsupported bezier curve order.")
            }
            return self
        }
}
