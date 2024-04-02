import Algorithms
import ApproximateEquality
import ApproximateEqualityMacros
import CoreGraphics
import CoreGraphicsSupport
import Foundation
import SwiftUI

public enum Line: Equatable {
    // https://byjus.com/maths/general-equation-of-a-line/

    case vertical(x: Double) // TODO: there are two vertical versions of this surely?
    case slopeIntercept(m: Double, y0: Double) // y = mx+y0
//    case general(a: Double, b: Double, c: Double) // Ax + By +C = 0,
}

public extension Line {
    init(points: (CGPoint, CGPoint)) {
        let x1 = points.0.x
        let y1 = points.0.y
        let x2 = points.1.x
        let y2 = points.1.y
        if x1 == x2 {
            self = .vertical(x: x1)
        }
        else {
            let m = (y2 - y1) / (x2 - x1)
            let y0 = y1 - m * x1
            self = .slopeIntercept(m: m, y0: y0)
        }
    }

    // TODO: Unconfirmed/untested
    // [+X, 0] == 0°, clockwise
    init(point: CGPoint, angle: Angle) {
        if angle.degrees == 90 || angle.degrees == 270 {
            self = .vertical(x: point.x)
        }
        else {
            let m = tan(angle.radians)
            let y0 = m * point.x + point.y
            self = .slopeIntercept(m: m, y0: -y0)
        }
    }
}

public extension Line {
    func rotate(angle: Angle) -> Line {
        fatalError()
    }

    func y(for x: Double) -> Double? {
        switch self {
        case .vertical:
            nil
        case .slopeIntercept(let m, let y0):
            m * x + y0
        }
    }

    var isHorizontal: Bool {
        m == 0
    }

    var isVertical: Bool {
        if case .vertical = self { true } else { false }
    }

    var m: Double? {
        if case .slopeIntercept(let m, _) = self { m } else { nil }
    }

    var y0: Double? {
        if case .slopeIntercept(_, let b) = self { b } else { nil }
    }

//    var rise: Double? {
//        fatalError()
//    }

//    var run: Double? {
//        fatalError()
//    }

    var xIntercept: Double? {
        switch self {
        case .vertical(let x):
            x
        case .slopeIntercept(let m, let y0):
            m != 0 ? -y0 / m : nil
        }
    }

    var yIntercept: Double? {
        y0
    }

    // TODO: Unconfirmed
    // [+X, 0] == 0°, clockwise
    var angle: Angle {
        switch self {
        case .vertical:
            .degrees(90)
        case .slopeIntercept(let m, _):
            .radians(atan(m))
        }
    }
}

public extension Line {
    enum Intersection: Equatable {
        case none
        case point(CGPoint)
        case everywhere
    }

    static func intersection(_ lhs: Line, _ rhs: Line) -> Intersection {
        if lhs == rhs {
            return .everywhere
        }
        switch (lhs, rhs) {
        case (.vertical, .vertical):
            return .everywhere
        case (.vertical, .slopeIntercept(_, let y0)):
            return .point(CGPoint(0, y0))
        case (.slopeIntercept(_, let y0), .vertical):
            return .point(CGPoint(0, y0))
        case (.slopeIntercept(let m1, let b1), .slopeIntercept(let m2, let b2)):
            if m1 == m2 {
                return .none
            }
            let x = (b2 - b1) / (m1 - m2)
            let y = m1 * x + b1
            return .point(CGPoint(x, y))
        }
    }
}

public extension Line {
    func compare(point: CGPoint) -> ComparisonResult {
        switch self {
        case .vertical(let x):
            ComparisonResult.compare(x, point.x)
        case .slopeIntercept(let m, let y0):
            ComparisonResult.compare(m * point.x + y0, point.y)
        }
    }
}

// MARK: -


// https://math.stackexchange.com/questions/2465810/length-of-a-line-inside-a-rectangle
public extension Line {
    func interceptsY(x: Double) -> Double? {
        switch self {
        case .vertical:
            nil
        case .slopeIntercept(let m, let y0):
            // TODO: Unit test
            m * x + y0
        }
    }

    func interceptsX(y: Double) -> Double? {
        switch self {
        case .vertical(let x):
            x
        case .slopeIntercept(let m, let y0):
            // TODO: Unit test
            (y + -y0) / m
        }
    }

//    func interceptsX(_ point: CGPoint) -> CGPoint? {
//        interceptsX(y: point.y).map { CGPoint($0, point.y) }
//    }

//    func interceptsY(_ point: CGPoint) -> CGPoint? {
//        interceptsY(x: point.x).map { CGPoint(point.x, $0) }
//    }

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
            let x0 = interceptsX(y: bounds.minY)!
            let y0 = interceptsY(x: bounds.minX)!
            return LineSegment(bounds.minX, y0, x0, bounds.minY)
        case 2, 13:
            let x0 = interceptsX(y: bounds.minY)!
            let y0 = interceptsY(x: bounds.maxX)!
            return LineSegment(bounds.maxX, y0, x0, bounds.minY)
        case 3, 12:
            let y0 = interceptsY(x: bounds.minX)!
            let y1 = interceptsY(x: bounds.maxX)!
            return LineSegment(bounds.minX, y0, bounds.maxX, y1)
        case 4, 11:
            let x0 = interceptsX(y: bounds.maxY)!
            let y0 = interceptsY(x: bounds.minX)!
            return LineSegment(bounds.minX, y0, x0, bounds.maxY)
        case 5, 10:
            let x0 = interceptsX(y: bounds.minY)!
            let x1 = interceptsX(y: bounds.maxY)!
            return LineSegment(CGPoint(x0, bounds.minY), CGPoint(x1, bounds.maxY))
        case 7, 8:
            let x0 = interceptsX(y: bounds.maxY)!
            let y0 = interceptsY(x: bounds.maxX)!
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
