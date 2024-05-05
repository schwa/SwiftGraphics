// swiftlint:disable identifier_name

import CoreGraphics
import CoreGraphicsSupport

public struct Polygon {
    public var vertices: [CGPoint]

    public init(_ vertices: [CGPoint]) {
        self.vertices = vertices
    }

    public enum Complexity {
        case simple
        case complex
    }

    public var complexity: Complexity {
        fatalError()
    }

    public func isConvex() -> Bool {
        if vertices.count < 4 {
            return true
        }
        var sign = false
        let n = vertices.count

        for i in 0 ..< vertices.count {
            let dx1 = vertices[(i + 2) % n].x - vertices[(i + 1) % n].x
            let dy1 = vertices[(i + 2) % n].y - vertices[(i + 1) % n].y
            let dx2 = vertices[i].x - vertices[(i + 1) % n].x
            let dy2 = vertices[i].y - vertices[(i + 1) % n].y
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
        let vertices = segments.flatMap {
            [$0.start, $0.end]
        }
        self.init(vertices)
    }

    
    func toLineSegments() -> [LineSegment] {
        precondition(vertices.count >= 3)
        let segments = stride(from: 0, to: vertices.count - 1, by: 1)
            .map { Array(vertices[$0 ..< $0 + 2]) }
            .map { ($0[0], $0[1]) }
            .map { LineSegment($0, $1) }
        return segments + [LineSegment(vertices.last!, vertices.first!)]
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
        let vertices = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY),
        ]
        self.init(vertices)
    }
}
