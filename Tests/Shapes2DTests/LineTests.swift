import CoreGraphicsSupport
@testable import Shapes2D
import SwiftUI
import XCTest

final class LineTests: XCTestCase {
    func testDistance() {
        let line = Line(a: 1, b: 1, c: 0)
        XCTAssertEqual(line.distance(to: CGPoint(x: 0, y: 0)), 0)
        XCTAssertEqual(line.distance(to: CGPoint(x: 1, y: 0)), 1 / sqrt(2))
        XCTAssertEqual(line.distance(to: CGPoint(x: 0, y: 1)), 1 / sqrt(2))
        XCTAssertEqual(line.distance(to: CGPoint(x: 0, y: -1)), 1 / sqrt(2))
    }

    func testPointOnLine() {
        XCTAssertTrue(Line(points: ([0, 0], [10, 0])).contains([-5, 0]))
        XCTAssertTrue(Line(points: ([0, 0], [10, 0])).contains([0, 0]))
        XCTAssertTrue(Line(points: ([0, 0], [10, 0])).contains([5, 0]))
        XCTAssertTrue(Line(points: ([0, 0], [10, 0])).contains([10, 0]))
        XCTAssertTrue(Line(points: ([0, 0], [10, 0])).contains([15, 0]))

        XCTAssertTrue(Line(points: ([0, 0], [0, 10])).contains([0, -5]))
        XCTAssertTrue(Line(points: ([0, 0], [0, 10])).contains([0, 0]))
        XCTAssertTrue(Line(points: ([0, 0], [0, 10])).contains([0, 5]))
        XCTAssertTrue(Line(points: ([0, 0], [0, 10])).contains([0, 10]))
        XCTAssertTrue(Line(points: ([0, 0], [0, 10])).contains([0, 15]))

        XCTAssertTrue(Line(points: ([0, 0], [10, 10])).contains([-5, -5]))
        XCTAssertTrue(Line(points: ([0, 0], [10, 10])).contains([0, 0]))
        XCTAssertTrue(Line(points: ([0, 0], [10, 10])).contains([5, 5]))
        XCTAssertTrue(Line(points: ([0, 0], [10, 10])).contains([10, 10]))
        XCTAssertTrue(Line(points: ([0, 0], [10, 10])).contains([15, 15]))
    }

    func testStandardFormSlopeIntercept() {
        let lines: [(Line, SlopeInterceptForm?)] = [
            (Line(a: 0, b: 1, c: 0), SlopeInterceptForm(m: 0, b: 0)),
            (Line(a: 0, b: 1, c: 1), SlopeInterceptForm(m: 0, b: 1)),
            (Line(a: 1, b: 0, c: 0), nil),
            (Line(a: 1, b: 0, c: 1), nil),
            (Line(a: 1, b: 1, c: 0), SlopeInterceptForm(m: -1, b: 0)),
            (Line(a: 1, b: 1, c: 1), SlopeInterceptForm(m: -1, b: 1)),

            (Line(a: 0, b: -1, c: 0), SlopeInterceptForm(m: 0, b: 0)),
            (Line(a: 0, b: -1, c: -1), SlopeInterceptForm(m: 0, b: 1)),
            (Line(a: -1, b: 0, c: 0), nil),
            (Line(a: -1, b: 0, c: -1), nil),
            (Line(a: -1, b: -1, c: 0), SlopeInterceptForm(m: -1, b: 0)),
            (Line(a: -1, b: -1, c: -1), SlopeInterceptForm(m: -1, b: 1)),
        ]

        for (line, slopeIntercept) in lines {
            XCTAssertEqual(line.slopeInterceptForm, slopeIntercept)
            if let slopeIntercept {
                XCTAssertEqual(line.normalized(), Line(slopeInterceptForm: slopeIntercept).normalized())
                XCTAssertEqual(line.slopeInterceptForm, Line(slopeInterceptForm: slopeIntercept).normalized().slopeInterceptForm)
            }
        }
    }
}
