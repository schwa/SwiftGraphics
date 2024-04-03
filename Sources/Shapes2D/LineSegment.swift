import Algorithms
import ApproximateEquality
import ApproximateEqualityMacros
import CoreGraphics
import CoreGraphicsSupport
import Foundation
import SwiftUI

@DeriveApproximateEquality
public struct LineSegment {
    public var start: CGPoint
    public var end: CGPoint

    public init(_ start: CGPoint, _ end: CGPoint) {
        self.start = start
        self.end = end
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
        return (end - start).length
    }
}

public extension LineSegment {
    func map(_ t: (CGPoint) throws -> CGPoint) rethrows -> LineSegment {
        try LineSegment(t(start), t(end))
    }

    func parallel(offset: Double) -> LineSegment {
        let angle = CGPoint.angle(start, end) - .degrees(90)
        let offset = CGPoint(distance: offset, angle: angle)
        return map { $0 + offset }
    }
}

