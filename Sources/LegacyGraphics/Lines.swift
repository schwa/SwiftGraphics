import CoreGraphics
import SwiftUI
import Support

public struct Lines {
    public let lineSegments: [LineSegment]

    public init(lineSegments: [LineSegment]) {
        self.lineSegments = lineSegments
    }
}

public extension Lines {
    init(points: [CGPoint]) {
        lineSegments = points.pairs().map { LineSegment(first: $0.0, second: $0.1!) }
    }
}

public extension Lines {
    static func cross(rect: CGRect) -> Lines {
        let points = [
            CGPoint(x: rect.minX, y: rect.midY), CGPoint(x: rect.maxX, y: rect.midY),
            CGPoint(x: rect.midX, y: rect.minY), CGPoint(x: rect.midX, y: rect.maxY),
        ]
        return Lines(points: points)
    }

    static func saltire(rect: CGRect) -> Lines {
        let points = [
            CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.minY),
        ]
        return Lines(points: points)
    }
}

extension Lines: Pathable {
    public func toPath() -> Path {
        var path = Path()
        for segment in lineSegments {
            path.move(to: segment.first)
            path.addLine(to: segment.second)
        }
        return path
    }
}
