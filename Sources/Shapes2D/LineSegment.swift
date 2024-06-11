import Algorithms
import ApproximateEquality
import CoreGraphics
import CoreGraphicsSupport
import Foundation
import SwiftUI

public struct LineSegment {
    public var start: CGPoint
    public var end: CGPoint

    public init(_ start: CGPoint, _ end: CGPoint) {
        self.start = start
        self.end = end
    }
}

extension LineSegment: ApproximateEquality {
    public func isApproximatelyEqual(to other: Self, absoluteTolerance: Double.Magnitude) -> Bool {
        start.isApproximatelyEqual(to: other.start, absoluteTolerance: CGPoint.Magnitude(absoluteTolerance))
        && end.isApproximatelyEqual(to: other.end, absoluteTolerance: CGPoint.Magnitude(absoluteTolerance))
    }
}

extension LineSegment: Codable {
}

extension LineSegment: Equatable {
}

// MARK: -

public extension LineSegment {
    init(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) {
        start = CGPoint(x0, y0)
        end = CGPoint(x1, y1)
    }

    var reversed: LineSegment {
        LineSegment(end, start)
    }

    var line: Line {
        Line(points: (start, end))
    }

    typealias Intersection = Line.Intersection

    static func intersection(_ lhs: LineSegment, _ rhs: LineSegment) -> Intersection {
        let lhs = lhs.line
        let rhs = rhs.line
        return Line.intersection(lhs, rhs)
    }

    var length: Double {
        (end - start).length
    }
}

public extension LineSegment {
    func map(_ t: (CGPoint) throws -> CGPoint) rethrows -> LineSegment {
        try LineSegment(t(start), t(end))
    }

    func parallel(offset: Double) -> LineSegment {
        let angle = Angle(from: start, to: end) - .degrees(90)
        let offset = CGPoint(distance: offset, angle: angle)
        return map { $0 + offset }
    }
}

// MARK: -

public enum LineSegmentIntersection {
    case intersect(CGPoint)
    case overlap(LineSegment)
    case endIntersect(CGPoint)
}

public extension LineSegment {
    func contains(_ point: CGPoint, tolerance: Double = 0.0) -> Bool {
        if point.x < min(start.x, end.x) - tolerance || point.x > max(start.x, end.x) + tolerance {
            return false
        }
        if point.y < min(start.y, end.y) - tolerance || point.y > max(start.y, end.y) + tolerance {
            return false
        }

        let line = Line(points: (start, end))
        return line.contains(point, tolerance: tolerance)
    }
}

public extension LineSegment {
    func intersection(_ other: LineSegment) -> CGPoint? {
        guard let intersection: LineSegmentIntersection = advancedIntersection(other) else {
            return nil
        }

        switch intersection {
        case .intersect(let intersection):
            return intersection
        case .endIntersect(let intersection):
            return intersection
        case .overlap:
            return nil
        }
    }

    // Adapted from: http://geomalgorithms.com/a05-_intersect-1.html
    // swiftlint:disable:next function_body_length
    func advancedIntersection(_ other: LineSegment) -> LineSegmentIntersection? {
        let smallNumber = CGPoint.Factor(0.00000001)

        let S1 = self
        let S2 = other

        let u = S1.end - S1.start
        let v = S2.end - S2.start
        let w = S1.start - S2.start
        let D = crossProduct(u, v)

        // test if they are parallel (includes either being a point)
        // S1 and S2 are parallel
        if abs(D) < smallNumber {
            // they are NOT collinear
            if crossProduct(u, w) != 0 || crossProduct(v, w) != 0 {
                return nil
            }
            // They are collinear or degenerate, check if they are degenerate points.
            let du = dotProduct(u, u)
            let dv = dotProduct(v, v)
            // both segments are points
            if du == 0 && dv == 0 {
                // they are distinct  points
                if S1.start != S2.start {
                    return nil
                }
                return .endIntersect(S1.start)
            }
            // S1 is a single point
            if du == 0 {
                // but is not in S2
                if S2.contains(S1.start) == false {
                    return nil
                }
                return .endIntersect(S1.start)
            }
            // S2 is a single point
            if dv == 0 {
                // but is not in S1
                if S1.contains(S2.start) == false {
                    return nil
                }
                return .endIntersect(S2.start)
            }
            // they are collinear segments - get overlap (or not)

            // endpoints of S1 in eqn for S2
            var t0: CGPoint.Factor, t1: CGPoint.Factor

            let w2 = S1.end - S2.start
            if v.x != 0 {
                t0 = w.x / v.x
                t1 = w2.x / v.x
            }
            else {
                t0 = w.y / v.y
                t1 = w2.y / v.y
            }

            // must have t0 smaller than t1
            if t0 > t1 {
                swap(&t0, &t1)
            }

            // No overlap
            if t0 > 1 || t1 < 0 {
                return nil
            }
            // clip to min 0
            t0 = t0 < 0 ? 0 : t0
            // clip to max 1
            t1 = t1 > 1 ? 1 : t1
            // intersect is a point
            if t0 == t1 {
                if t0 == 0 {
                    assert((S2.start + t0 * v) == S2.start)
                    return .endIntersect(S2.start)
                }
                else if t0 == 1 {
                    assert((S2.start + t0 * v) == S2.end)
                    return .endIntersect(S2.end)
                }
                return .intersect(S2.start + t0 * v)
            }
            // they overlap in a valid subsegment
            return .overlap(LineSegment(S2.start + t0 * v, S2.start + t1 * v))
        }

        // the segments are skew and may intersect in a point
        // get the intersect parameter for S1
        let sI = crossProduct(v, w) / D
        // no intersect with S1
        if sI < 0 || sI > 1 {
            return nil
        }

        // get the intersect parameter for S2
        let tI = crossProduct(u, w) / D
        // no intersect with S2
        if tI < 0 || tI > 1 {
            return nil
        }

        if sI == 0 {
            assert((S1.start + sI * u) == S1.start)
            return .endIntersect(S1.start)
        }
        else if sI == 1 {
            assert((S1.start + sI * u) == S1.end)
            return .endIntersect(S1.end)
        }

        return .intersect(S1.start + sI * u)
    }
}
