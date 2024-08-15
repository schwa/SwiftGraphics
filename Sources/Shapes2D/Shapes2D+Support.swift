import CoreGraphics
import Foundation

extension ComparisonResult {
    static func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        if lhs == rhs {
            .orderedSame
        } else if lhs < rhs {
            .orderedAscending
        } else {
            .orderedDescending
        }
    }
}

/// Return true if a, b, and c all lie on the same line.
public func collinear(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, absoluteTolerance: Double.Magnitude) -> Bool {
    let lhs = (b.x - a.x) * (c.y - a.y)
    let rhs = (c.x - a.x) * (b.y - a.y)
    return lhs.isApproximatelyEqual(to: rhs, absoluteTolerance: absoluteTolerance)
}
