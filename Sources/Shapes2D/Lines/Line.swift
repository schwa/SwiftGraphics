import Algorithms
import CoreGraphics
import CoreGraphicsSupport
import Foundation
import SwiftUI

// https://www.desmos.com/calculator/gtdbajcu41
// https://www.wolframalpha.com/input?i=line
// https://byjus.com/maths/general-equation-of-a-line/
// https://www.omnicalculator.com/math/standard-form-to-slope-intercept-form
// https://www.wolframalpha.com/widgets/view.jsp?id=4be4308d0f9d17d1da68eea39de9b2ce

public typealias StandardFormLine = Line

public struct Line: Equatable {
    public var a, b, c: Double

    public init(a: Double, b: Double, c: Double) {
        assert(a != 0 || b != 0)
        self.a = a
        self.b = b
        self.c = c
    }
}

public extension Line {
    static func horizontal(y: Double) -> Self {
        .init(a: 0, b: 1, c: -y)
    }

    static func vertical(x: Double) -> Self {
        .init(a: 1, b: 0, c: x)
    }

    init(_ tuple: (a: Double, b: Double, c: Double)) {
        self = .init(a: tuple.a, b: tuple.b, c: tuple.c)
    }
}

public extension Line {
    var isHorizontal: Bool {
        a == 0
    }

    var isVertical: Bool {
        b == 0
    }

    func x(forY y: Double) -> Double? {
        a == 0 ? 0 : (c - b * y) / a
    }

    func y(forX x: Double) -> Double? {
        b == 0 ? nil : -((-c + a * x) / b)
    }

    var xIntercept: CGPoint? {
        isHorizontal ? nil : CGPoint(c / a, 0)
    }

    var yIntercept: CGPoint? {
        isVertical ? nil : CGPoint(0, c / b)
    }

    var slope: Double {
        -a / b
    }

    var angle: Angle {
        .radians(atan(slope))
    }
}

// MARK: -

public extension Line {
    init(points: (CGPoint, CGPoint)) {
        let x1 = points.0.x
        let y1 = points.0.y
        let x2 = points.1.x
        let y2 = points.1.y
        if x1 == x2 {
            self.init(a: 1, b: 0, c: x1)
        } else {
            let m = (y2 - y1) / (x2 - x1)
            let b = y1 - m * x1
            self = .slopeIntercept(m: m, b: b)
        }
    }
}

public extension Line {
    // [+X, 0] == 0°, clockwise
    init(point: CGPoint, angle: Angle) {
        if angle.degrees == 90 || angle.degrees == 270 {
            self.init(a: 1, b: 0, c: point.x)
        } else {
            let m = tan(angle.radians)
            let b = -m * point.x + point.y
            self = .slopeIntercept(m: m, b: b)
        }
    }
}

// MARK: -

public extension Line {
    func normalized() -> Line {
        var result = self
        if b != 0 {
            result.a = 1.0 / b * result.a
            result.b = 1.0 / b * result.b
            result.c = 1.0 / b * result.c
        }
        return result
    }
}
