import Foundation
import SwiftUI

// We treat SwiftUI.Angle as part of CoreGraphics - because it's too useful not to be.

public extension Angle {
    init(to point: CGPoint) {
        self = Angle(radians: CoreGraphics.atan2(point.y, point.x))
    }

    init(from lhs: CGPoint, to rhs: CGPoint) {
        self = Angle(radians: CoreGraphics.atan2(rhs.y - lhs.y, rhs.x - lhs.x))
    }

    init(vertex: CGPoint, p1: CGPoint, p2: CGPoint) {
        self = Angle(from: p1, to: vertex) - Angle(from: p2, to: vertex)
    }

    static func atan2(y: CGFloat, x: CGFloat) -> Angle {
        .init(radians: CoreGraphics.atan2(y, x))
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
        }
        else {
            return .degrees(degrees)
        }
    }
}
