// swiftlint:disable identifier_name

import CoreGraphics
import Everything

public enum LineSegmentIntersection {
    case intersect(CGPoint)
    case overlap(LineSegment)
    case endIntersect(CGPoint)
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
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func advancedIntersection(_ other: LineSegment) -> LineSegmentIntersection? {
        let smallNumber = CGPoint.Factor(0.000_000_01)

        let S1 = self
        let S2 = other

        let u = S1.second - S1.first
        let v = S2.second - S2.first
        let w = S1.first - S2.first
        let D = perpProduct(u, v)

        // test if they are parallel (includes either being a point)
        // S1 and S2 are parallel
        if abs(D) < smallNumber {
            // they are NOT collinear
            if perpProduct(u, w) != 0 || perpProduct(v, w) != 0 {
                return nil
            }
            // They are collinear or degenerate, check if they are degenerate points.
            let du = dotProduct(u, u)
            let dv = dotProduct(v, v)
            // both segments are points
            if du == 0 && dv == 0 {
                // they are distinct  points
                if S1.first != S2.first {
                    return nil
                }
                return .endIntersect(S1.first)
            }
            // S1 is a single point
            if du == 0 {
                // but is not in S2
                if S2.containsPoint(S1.first) == false {
                    return nil
                }
                return .endIntersect(S1.first)
            }
            // S2 is a single point
            if dv == 0 {
                // but is not in S1
                if S1.containsPoint(S2.first) == false {
                    return nil
                }
                return .endIntersect(S2.first)
            }
            // they are collinear segments - get overlap (or not)

            // endpoints of S1 in eqn for S2
            var t0: CGPoint.Factor, t1: CGPoint.Factor

            let w2 = S1.second - S2.first
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
                    assert((S2.first + t0 * v) == S2.first)
                    return .endIntersect(S2.first)
                }
                else if t0 == 1 {
                    assert((S2.first + t0 * v) == S2.second)
                    return .endIntersect(S2.second)
                }
                return .intersect(S2.first + t0 * v)
            }
            // they overlap in a valid subsegment
            return .overlap(LineSegment(first: S2.first + t0 * v, second: S2.first + t1 * v))
        }

        // the segments are skew and may intersect in a point
        // get the intersect parameter for S1
        let sI = perpProduct(v, w) / D
        // no intersect with S1
        if sI < 0 || sI > 1 {
            return nil
        }

        // get the intersect parameter for S2
        let tI = perpProduct(u, w) / D
        // no intersect with S2
        if tI < 0 || tI > 1 {
            return nil
        }

        if sI == 0 {
            assert((S1.first + sI * u) == S1.first)
            return .endIntersect(S1.first)
        }
        else if sI == 1 {
            assert((S1.first + sI * u) == S1.second)
            return .endIntersect(S1.second)
        }

        return .intersect(S1.first + sI * u)
    }
}
