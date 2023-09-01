// swiftlint:disable identifier_name

import CoreGraphics
import Everything

public struct Polygon {
    public let points: [CGPoint]

    public init(points: [CGPoint]) {
        self.points = points
    }

    public enum Complexity {
        case simple
        case complex
    }

    public var complexity: Complexity {
        unimplemented()
    }

    public func isConvex() -> Bool {
        if points.count < 4 {
            return true
        }
        var sign = false
        let n = points.count

        for i in 0 ..< points.count {
            let dx1 = points[(i + 2) % n].x - points[(i + 1) % n].x
            let dy1 = points[(i + 2) % n].y - points[(i + 1) % n].y
            let dx2 = points[i].x - points[(i + 1) % n].x
            let dy2 = points[i].y - points[(i + 1) % n].y
            let zcrossproduct = dx1 * dy2 - dy1 * dx2
            if i == 0 {
                sign = zcrossproduct > 0
            }
            else if sign != (zcrossproduct > 0) {
                return false
            }
        }
        return true
    }
}

public extension Polygon {
    init(segments: [LineSegment]) {
        let points = segments.flatMap {
            [$0.first, $0.second]
        }
        self.init(points: points)
    }

    func toLineSegments() -> [LineSegment] {
        precondition(points.count >= 3)
        let segments = stride(from: 0, to: points.count - 1, by: 1)
            .map { Array(points[$0 ..< $0 + 2]) }
            .map { ($0[0], $0[1]) }
            .map { LineSegment(first: $0, second: $1) }
        return segments + [LineSegment(first: points.last!, second: points.first!)]
    }
}

public extension Polygon {
    func intersections(_ segment: LineSegment) -> [CGPoint] {
        let segments: [LineSegment] = toLineSegments()
        return segments.compactMap {
            $0.intersection(segment)
        }
    }
}

public extension Polygon {
    init(rect: CGRect) {
        let points = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY),
        ]
        self.init(points: points)
    }
}
