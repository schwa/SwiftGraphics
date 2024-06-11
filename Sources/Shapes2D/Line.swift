import Algorithms
import ApproximateEquality
import CoreGraphics
import CoreGraphicsSupport
import Foundation
import SwiftUI

// public typealias Line = Line
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
        (-c / b) / (c / a)
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
        }
        else {
            let m = (y2 - y1) / (x2 - x1)
            let b = y1 - m * x1
            self = .init(slopeInterceptFormToStandardForm(m: m, b: b))
        }
    }
}

// TODO:
// public extension Line {
//    init(point: CGPoint, slope: Double) {
//        fatalError()
//    }
// }

public extension Line {
    // TODO: Unconfirmed/untested
    // [+X, 0] == 0°, clockwise
    init(point: CGPoint, angle: Angle) {
        if angle.degrees == 90 || angle.degrees == 270 {
            self.init(a: 1, b: 0, c: point.x)
        }
        else {
            let m = tan(angle.radians)
            let b = -m * point.x + point.y
            self = .init(slopeInterceptFormToStandardForm(m: m, b: b))
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

// MARK: Line Intersection

public extension Line {
    enum Intersection: Equatable {
        case none
        case point(CGPoint)
        case everywhere
    }

    static func intersection(_ lhs: Self, _ rhs: Self) -> Intersection {
        // TODO: we can clean this up tremendously (write unit tests first!), get rid of forced unwraps.
        if lhs == rhs {
            return .everywhere
        }

        func verticalIntersection(line: Self, x: Double) -> CGPoint {
            let y = line.y(forX: x)!
            return CGPoint(x: x, y: y)
        }

        switch (lhs.isVertical, rhs.isVertical) {
        case (true, true):
            // Two vertical lines.
            return lhs.xIntercept == rhs.xIntercept ? .everywhere : .none
        case (false, true):
            let point = verticalIntersection(line: lhs, x: rhs.xIntercept!.x)
            return .point(point)
        case (true, false):
            let point = verticalIntersection(line: rhs, x: lhs.xIntercept!.x)
            return .point(point)
        case (false, false):
            let lhs = lhs.slopeInterceptForm!
            let rhs = rhs.slopeInterceptForm!
            if lhs.m == rhs.m {
                return .none
            }
            let x = (rhs.b - lhs.b) / (lhs.m - rhs.m)
            let y = lhs.m * x + lhs.b
            return .point(CGPoint(x, y))
        }
    }
}

// TODO:
// public extension Line {
//    func rotate(angle: Angle) -> Line {
//        fatalError()
//    }
//
//    func reflect(point: CGPoint) -> CGPoint {
//    }
// }

// MARK: -

public extension Line {
    func compare(point: CGPoint) -> ComparisonResult {
        if isVertical {
            return ComparisonResult.compare(xIntercept!.x, point.x)
        }
        else {
            let (m, b) = slopeInterceptForm!.tuple
            return ComparisonResult.compare(m * point.x + b, point.y)
        }
    }
}

public extension Line {
    func lineSegment(bounds: CGRect) -> LineSegment? {
        /*
         0: 2---3  1: 2---3  2: 2---3  3: 2---3  4: 2--X3  5: 2-X-3  6: 2---3  7: 2X--3
            |   |     X   |     |   X     |   |     | / |     | | |     |   |     | \ |
            |   |     |\  |     |  /|     X---X     |/  |     | | |     |   |     |  \|
            |   |     | \ |     | / |     |   |     X   |     | | |     |   |     |   X
            0---1     0--X1     0X--1     0---1     0---1     0-X-1     0---1     0---1

         8: 2X--3  9: 2---3 10: 2-X-3 11: 2--X3 12: 2---3 13: 2---3 14: 2---3 15: 2---3
            | \ |     |   |     | | |     | / |     |   |     |   X     X   |     |   |
            |  \|     |   |     | | |     |/  |     X---X     |  /|     |\  |     |   |
            |   X     |   |     | | |     X   |     |   |     | / |     | \ |     |   |
            0---1     0---1     0-X-1     0---1     0---1     0X--1     0--X1     0---1

         */
        let corner_0 = (compare(point: bounds.minXMinY) == .orderedDescending) ? 1 : 0
        let corner_1 = (compare(point: bounds.maxXMinY) == .orderedDescending) ? 1 : 0
        let corner_2 = (compare(point: bounds.minXMaxY) == .orderedDescending) ? 1 : 0
        let corner_3 = (compare(point: bounds.maxXMaxY) == .orderedDescending) ? 1 : 0
        switch corner_3 << 3 | corner_2 << 2 | corner_1 << 1 | corner_0 << 0 {
        case 1, 14:
            let x0 = x(forY: bounds.minY)!
            let y0 = y(forX: bounds.minX)!
            return LineSegment(bounds.minX, y0, x0, bounds.minY)
        case 2, 13:
            let x0 = x(forY: bounds.minY)!
            let y0 = y(forX: bounds.maxX)!
            return LineSegment(bounds.maxX, y0, x0, bounds.minY)
        case 3, 12:
            let y0 = y(forX: bounds.minX)!
            let y1 = y(forX: bounds.maxX)!
            return LineSegment(bounds.minX, y0, bounds.maxX, y1)
        case 4, 11:
            let x0 = x(forY: bounds.maxY)!
            let y0 = y(forX: bounds.minX)!
            return LineSegment(bounds.minX, y0, x0, bounds.maxY)
        case 5, 10:
            let x0 = x(forY: bounds.minY)!
            let x1 = x(forY: bounds.maxY)!
            return LineSegment(CGPoint(x0, bounds.minY), CGPoint(x1, bounds.maxY))
        case 7, 8:
            let x0 = x(forY: bounds.maxY)!
            let y0 = y(forX: bounds.maxX)!
            return LineSegment(CGPoint(bounds.maxX, y0), CGPoint(x0, bounds.maxY))
        default:
            return nil
        }
    }
}

// binary   3 2 1 0  class
// 0  0000    ≤ ≤ ≤ ≤    0
// 1  0001    ≤ ≤ ≤ >    1
// 2  0010    ≤ ≤ > ≤    1
// 3  0011    ≤ ≤ > >    2
// 4  0100    ≤ > ≤ ≤    1
// 5  0101    ≤ > ≤ >    2
// 6  0110    ≤ > > ≤    0
// 7  0111    ≤ > > >    1
// 8  1000    > ≤ ≤ ≤    1
// 9  1001    > ≤ ≤ >    0
// 10  1010    > ≤ > ≤    2
// 11  1011    > ≤ > >    1
// 12  1100    > > ≤ ≤    2
// 13  1101    > > ≤ >    1
// 14  1110    > > > ≤    1
// 15  1111    > > > >    0

// MARK: -

public extension Line {
    func distance(to point: CGPoint) -> Double {
        if isVertical {
            return abs(point.x - xIntercept!.x)
        }
        else {
            let (m, b) = slopeInterceptForm!.tuple
            return abs(m * point.x - point.y + b) / sqrt(m * m + 1)
        }
    }

    func contains(_ point: CGPoint, tolerance: Double = 0.0) -> Bool {
        abs(distance(to: point)) <= tolerance
    }
}
