import Algorithms
import BaseSupport
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

public extension LineSegment {
    func isApproximatelyEqual(to other: Self, absoluteTolerance: Double.Magnitude) -> Bool {
        start.isApproximatelyEqual(to: other.start, absoluteTolerance: CGPoint.Magnitude(absoluteTolerance))
        && end.isApproximatelyEqual(to: other.end, absoluteTolerance: CGPoint.Magnitude(absoluteTolerance))
    }
}

extension LineSegment: Codable {
}

extension LineSegment: Equatable {
}

extension LineSegment: Sendable {
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

    var length: Double {
        (end - start).length
    }
}

public extension LineSegment {
    func map(_ t: (CGPoint) throws -> CGPoint) rethrows -> LineSegment {
        try LineSegment(t(start), t(end))
    }

    func parallel(offset: Double) -> LineSegment {
        // Calculate the direction vector of the line
        let dx = end.x - start.x
        let dy = end.y - start.y

        // Calculate the length of the line
        let length = sqrt(dx * dx + dy * dy)

        // Calculate the unit normal vector
        let nx = -dy / length
        let ny = dx / length

        // Calculate the offset vector
        let offsetX = nx * CGFloat(offset)
        let offsetY = ny * CGFloat(offset)

        // Create the new start and end points
        let newStart = CGPoint(x: start.x + offsetX, y: start.y + offsetY)
        let newEnd = CGPoint(x: end.x + offsetX, y: end.y + offsetY)

        // Return the new parallel line segment
        return LineSegment(newStart, newEnd)
    }
}
