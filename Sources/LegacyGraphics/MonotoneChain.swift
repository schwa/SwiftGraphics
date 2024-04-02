// https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain

import CoreGraphics
import LegacyGeometry

// O(n log n)

public struct MonotoneChain: ConvexHullProtocol {
    public static func convexHull(points: [CGPoint], presorted: Bool) -> [CGPoint] {
        var points = points

        if points.count <= 3 {
            return points
        }

        if presorted == false {
            func compareXY(lhs: CGPoint, rhs: CGPoint) -> Bool {
                lhs.x < rhs.x ? true : (lhs.x == rhs.x ? (lhs.y < rhs.y ? true : false) : false)
            }
            points.sort(by: compareXY)
        }

        var lower: [CGPoint] = []
        for i in 0 ..< points.count {
            while lower.count >= 2 && Turn(lower[lower.count - 2], lower[lower.count - 1], points[i]) != .right {
                lower.removeLast()
            }
            lower.append(points[i])
        }

        var upper: [CGPoint] = []
        for i in stride(from: points.count - 1, to: 0, by: -1) {
            while upper.count >= 2 && Turn(upper[upper.count - 2], upper[upper.count - 1], points[i]) != .right {
                upper.removeLast()
            }
            upper.append(points[i])
        }

        lower.removeLast()
        upper.removeLast()

        let hull = lower + upper

        assert(hull.count <= points.count, "Ended up with more points in hull (\(hull.count)) than in origin set (\(points.count)).")

        return hull
    }
}
