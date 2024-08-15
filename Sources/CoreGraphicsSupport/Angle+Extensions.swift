import BaseSupport
import Foundation
import SwiftUI

// We treat SwiftUI.Angle as part of CoreGraphics - because it's too useful not to be.

public extension Angle {
    static func atan2(y: CGFloat, x: CGFloat) -> Angle {
        .init(radians: CoreGraphics.atan2(y, x))
    }

    init(from lhs: CGPoint = .zero, to rhs: CGPoint) {
        let delta = rhs - lhs
        self = .atan2(y: delta.y, x: delta.x)
    }

    init(vertex: CGPoint, p1: CGPoint, p2: CGPoint, clockwise: Bool = false) {
        let angle1 = Angle(from: vertex, to: p1)
        let angle2 = Angle(from: vertex, to: p2)
        self = !clockwise ? angle2 - angle1 : angle1 - angle2
    }
}

public extension Angle {
    static func / (lhs: Self, rhs: Self) -> Self {
        .init(radians: lhs.radians / rhs.radians)
    }

    static func /= (lhs: inout Self, rhs: Self) {
        lhs.radians /= rhs.radians
    }

    func truncatingRemainder(dividingBy d: Self) -> Self {
        .radians(radians.truncatingRemainder(dividingBy: d.radians))
    }
}

// MARK: -

public func abs(_ value: Angle) -> Angle {
    .radians(Swift.abs(value.radians))
}

public extension Angle {
    // Normalized between 0° and 360°
    var normalized: Angle {
        let degrees = degrees.truncatingRemainder(dividingBy: 360)
        if degrees < 0 {
            return .degrees(degrees + 360)
        } else {
            return .degrees(degrees)
        }
    }
}

public extension Angle {
    func isApproximatelyEqual(to other: Angle, absoluteTolerance: Angle) -> Bool {
        radians.isApproximatelyEqual(to: other.radians, absoluteTolerance: absoluteTolerance.radians)
    }
}
