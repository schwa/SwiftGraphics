import CoreGraphics
import Foundation

// swiftlint:disable force_unwrapping

internal extension Line {
    func compare(point: CGPoint) -> ComparisonResult {
        if isVertical {
            return ComparisonResult.compare(xIntercept!.x, point.x)
        } else {
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

public extension LineSegment {
    var line: Line {
        Line(points: (start, end))
    }
}
