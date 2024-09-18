import CoreGraphicsSupport
import Shapes2D
import SwiftUI

struct Spline {
    struct Knot {
        var position: CGPoint
        enum ControlPoint {
            case split(CGPoint, CGPoint)
            // case aligned(CGPoint, CGPoint)
            case mirrored(CGPoint)
        }

        var controlPoint: ControlPoint

        init(position: CGPoint, controlPoint: ControlPoint = .mirrored(.zero)) {
            self.position = position
            self.controlPoint = controlPoint
        }
    }

    var knots: [Knot]

    init(knots: [Knot] = []) {
        self.knots = knots
    }
}

extension Spline {
    var curves: [CubicBezierCurve] {
        knots.adjacentPairs().enumerated().map { index, knots in
            CubicBezierCurve(controlPoints: (
                knots.0.position,
                index.isEven ? knots.0.position + knots.0.controlPointA : knots.0.position - knots.0.controlPointB,
                index.isEven ? knots.0.position + knots.1.controlPointA : knots.0.position - knots.1.controlPointB,
                knots.1.position
            ))
        }
    }
}

extension Spline.Knot {
    var controlPointA: CGPoint {
        get {
            switch controlPoint {
            case .mirrored(let position):
                position
            case .split(let positionA, _):
                positionA
            }
        }
        set {
            switch controlPoint {
            case .mirrored:
                controlPoint = .mirrored(newValue)
            case .split(_, let positionB):
                controlPoint = .split(newValue, positionB)
            }
        }
    }

    var controlPointB: CGPoint {
        get {
            switch controlPoint {
            case .mirrored(let position):
                -position
            case .split(_, let positionB):
                positionB
            }
        }
        set {
            switch controlPoint {
            case .mirrored:
                controlPoint = .mirrored(-newValue)
            case .split(let positionA, _):
                controlPoint = .split(positionA, -newValue)
            }
        }
    }

    var absoluteControlPointA: CGPoint {
        get {
            switch controlPoint {
            case .mirrored(let position):
                self.position + position
            case .split(let positionA, _):
                position + positionA
            }
        }
        set {
            switch controlPoint {
            case .mirrored:
                controlPoint = .mirrored(newValue - position)
            case .split(_, let positionB):
                controlPoint = .split(newValue - position, positionB)
            }
        }
    }

    var absoluteControlPointB: CGPoint {
        get {
            switch controlPoint {
            case .mirrored(let position):
                self.position - position
            case .split(_, let positionB):
                position - positionB
            }
        }
        set {
            switch controlPoint {
            case .mirrored:
                controlPoint = .mirrored(-(newValue - position))
            case .split(let positionA, _):
                controlPoint = .split(positionA, -(newValue - position))
            }
        }
    }
}

extension Spline: PathConvertible {
    var path: Path {
        Path(paths: curves.map(\.path))
    }
}

extension Spline {
    func split(at point: CGPoint) -> Spline? {
        guard knots.count >= 2 else {
            return nil
        }
        guard let index = curves.firstIndex(where: { curve in
            curve.contains(point)
        }) else {
            return nil
        }
        //        let knots = (knots[index], knots[index + 1])
        //
        //
        //
        //        spline.knots.insert(.init(position: (knots.0.position + knots.1.position) / 2, controlPoint: .zero), at: index)

        let knot = Knot(position: (knots[index].position + knots[index + 1].position) / 2)

        return Spline(knots: Array(knots[..<index]) + [knot] + Array(knots[index...]))
    }
}

extension Spline {
    var comb: [LineSegment] {
        curves.flatMap(\.comb)
    }
}

// MARK: -

extension CubicBezierCurve {
    var comb: [LineSegment] {
        render().windows(ofCount: 3).map { points in
            let (p0, p1, p2) = (points[offset: 0], points[offset: 1], points[offset: 2])
            let angle = (Angle(vertex: points[offset: 1], p1: points[offset: 0], p2: points[offset: 2]) + 360).truncatingRemainder(dividingBy: 360)
            let curve = (abs(angle - 180) / 180).degrees
            let normal = ((p1 - p0).normalized + (p1 - p2).normalized).normalized
            return LineSegment(p1, p1 + normal * curve * 10)
        }
    }
}

extension CubicBezierCurve: PathConvertible {
    public var path: Path {
        Path { path in
            path.move(to: controlPoints.0)
            path.addCurve(to: controlPoints.3, control1: controlPoints.1, control2: controlPoints.2)
        }
    }
}

extension CubicBezierCurve {
    func contains(_ point: CGPoint) -> Bool {
        Path(self).contains(point)
    }
}
