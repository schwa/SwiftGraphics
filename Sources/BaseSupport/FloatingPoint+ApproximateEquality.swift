public extension FloatingPoint {
    func isApproximatelyEqual(to rhs: Self, absoluteTolerance: Self) -> Bool {
        abs(self - rhs) <= absoluteTolerance
    }
}
