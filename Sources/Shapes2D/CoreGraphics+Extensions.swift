import CoreGraphics

public extension CGRect {
    var edges: [LineSegment] {
        [
            LineSegment(minXMinY, maxXMinY),
            LineSegment(maxXMinY, maxXMaxY),
            LineSegment(maxXMaxY, maxXMinY),
            LineSegment(maxXMinY, minXMinY),
        ]
    }
}
