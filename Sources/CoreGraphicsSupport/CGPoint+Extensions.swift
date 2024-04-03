//
//  File.swift
//  
//
//  Created by Jonathan Wight on 4/2/24.
//

import Foundation
//import struct SwiftUI.Angle
import SwiftUI

public extension CGPoint {
    init(origin: CGPoint = .zero, distance d: Double, angle: Angle) {
        self = CGPoint(x: origin.x + Darwin.cos(angle.radians) * d, y: origin.y + sin(angle.radians) * d)
    }

    var angle: Angle {
        .radians(atan2(y, x))
    }

    var magnitude: Double {
        x * x + y * y
    }

    var distance: Double {
        sqrt(magnitude)
    }

    var normalized: CGPoint {
        self / distance
    }

    static func angle(_ lhs: CGPoint, _ rhs: CGPoint) -> Angle {
        let d = rhs - lhs
        return d.angle
    }

    static func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> Double {
        let d = rhs - lhs
        return sqrt(d.x * d.x + d.y * d.y)
    }

    static func distance(_ points: (CGPoint, CGPoint)) -> Double {
        distance(points.0, points.1)
    }
}

public extension CGPoint {
    func map(_ f: (Double) -> Double) -> CGPoint {
        CGPoint(x: f(x), y: f(y))
    }
}

public extension CGPoint {
    var length: Double {
        get {
            sqrt(lengthSquared)
        }
        set {
            self = .init(distance: newValue, angle: angle)
        }
    }

    var lengthSquared: Double {
        x * x + y * y
    }
}
