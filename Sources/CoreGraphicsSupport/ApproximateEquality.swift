import BaseSupport
import CoreGraphics
import SwiftUI

public extension CGPoint {
    typealias Magnitude = CGFloat

    func isApproximatelyEqual(to rhs: Self, absoluteTolerance: Magnitude) -> Bool {
        x.isApproximatelyEqual(to: rhs.x, absoluteTolerance: absoluteTolerance)
        && y.isApproximatelyEqual(to: rhs.y, absoluteTolerance: absoluteTolerance)
    }
}

public extension Angle {
    typealias Magnitude = Double

    func isApproximatelyEqual(to rhs: Self, absoluteTolerance: Magnitude) -> Bool {
        radians.isApproximatelyEqual(to: rhs.radians, absoluteTolerance: absoluteTolerance)
    }
}
