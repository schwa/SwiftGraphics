import CoreGraphics

// O(n log n)
public struct GrahamScan: ConvexHullProtocol {
    public static func convexHull(points: [CGPoint], presorted: Bool) -> [CGPoint] {
        var points = points

        if points.count <= 3 {
            return points
        }

        if presorted == false {
            points = grahamOrdered(points: points)
        }

        var hull: [Int] = [0, 1]

        for index in 2 ..< points.count {
            var t: Turn = .left
            repeat {
                let p_index = hull[hull.count - 2] // TODO: There seems to be a crasher here!!!
                let p = points[p_index]
                let q_index = hull[hull.count - 1]
                let q = points[q_index]
                let r = points[index]
                t = Turn(p, q, r)
                if t != .right {
                    hull.removeLast()
                }
            }
            while t != .right

            hull.append(index)
        }

        return hull.map {
            points[$0]
        } as [CGPoint]
    }

    static func grahamOrdered(points: [CGPoint]) -> [CGPoint] {
        // Find the point (and its index) with the lowest y
        typealias IndexedPoint = (offset: Int, element: CGPoint)

        let lowest = points.enumerated().reduce(IndexedPoint(0, points[0])) { (u: IndexedPoint, c: IndexedPoint) -> IndexedPoint in
            c.element.y < u.element.y ? c : (c.element.y == u.element.y ? (c.element.x <= u.element.x ? c : u) : u)
        }

        var points = points
        points.remove(at: lowest.offset)
        points.sort {
            Turn(lowest.element, $0, $1) <= .none
        }
        points.insert(lowest.element, at: 0)
        return points
    }
}
