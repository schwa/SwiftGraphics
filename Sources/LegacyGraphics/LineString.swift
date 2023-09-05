import CoreGraphics

public struct LineString {
    public let points: [CGPoint]

    public init(points: [CGPoint]) {
        self.points = points
    }
}

public extension LineString {
    init(segments: [LineSegment]) {
        let points = segments.flatMap {
            [$0.first, $0.second]
        }
        self.init(points: points)
    }

    func toLineSegments() -> [LineSegment] {
        precondition(points.count >= 2)
        let pairs = stride(from: 0, to: points.count - 1, by: 1)
            .map { Array(points[$0 ..< $0 + 2]) }
            .map { ($0[0], $0[1]) }

        return pairs.map { LineSegment(first: $0, second: $1) }
    }
}

public extension LineString {
    func intersections(_ segment: LineSegment) -> [CGPoint] {
        let segments = toLineSegments()
        return segments.compactMap {
            $0.intersection(segment)
        }
    }
}
