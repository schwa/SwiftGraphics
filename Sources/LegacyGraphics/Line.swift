import CoreGraphics

// MARK: Line

public struct Line {
    let m: CGFloat
    let b: CGFloat

    // TODO: Vertical lines!?
    func lineSegment(x0: CGFloat, x1: CGFloat) -> LineSegment {
        let start = CGPoint(x: x0, y: m * x0 + b)
        let end = CGPoint(x: x1, y: m * x1 + b)
        return LineSegment(first: start, second: end)
    }
}
