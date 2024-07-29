import CoreGraphics

public extension FloatingPoint {
    func isApproximatelyEqual(to rhs: Self, absoluteTolerance: Self) -> Bool {
        abs(self - rhs) <= absoluteTolerance
    }
}

public extension CGPoint {
    typealias Magnitude = CGFloat

    func isApproximatelyEqual(to rhs: Self, absoluteTolerance: Magnitude) -> Bool {
        x.isApproximatelyEqual(to: rhs.x, absoluteTolerance: absoluteTolerance)
        && y.isApproximatelyEqual(to: rhs.y, absoluteTolerance: absoluteTolerance)
    }
}
