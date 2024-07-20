@testable import Shapes2D
import SwiftUI
import Testing
import CoreGraphicsUnsafeConformances

@Test func testDistance() {
    let line = Line(a: 1, b: 1, c: 0)
    #expect(line.distance(to: CGPoint(x: 0, y: 0)) == 0)
    #expect(line.distance(to: CGPoint(x: 1, y: 0)) == 1 / sqrt(2))
    #expect(line.distance(to: CGPoint(x: 0, y: 1)) == 1 / sqrt(2))
    #expect(line.distance(to: CGPoint(x: 0, y: -1)) == 1 / sqrt(2))
}

@Test func testPointOnLine() {
    #expect(Line(points: ([0, 0], [10, 0])).contains([-5, 0]))
    #expect(Line(points: ([0, 0], [10, 0])).contains([0, 0]))
    #expect(Line(points: ([0, 0], [10, 0])).contains([5, 0]))
    #expect(Line(points: ([0, 0], [10, 0])).contains([10, 0]))
    #expect(Line(points: ([0, 0], [10, 0])).contains([15, 0]))

    #expect(Line(points: ([0, 0], [0, 10])).contains([0, -5]))
    #expect(Line(points: ([0, 0], [0, 10])).contains([0, 0]))
    #expect(Line(points: ([0, 0], [0, 10])).contains([0, 5]))
    #expect(Line(points: ([0, 0], [0, 10])).contains([0, 10]))
    #expect(Line(points: ([0, 0], [0, 10])).contains([0, 15]))

    #expect(Line(points: ([0, 0], [10, 10])).contains([-5, -5]))
    #expect(Line(points: ([0, 0], [10, 10])).contains([0, 0]))
    #expect(Line(points: ([0, 0], [10, 10])).contains([5, 5]))
    #expect(Line(points: ([0, 0], [10, 10])).contains([10, 10]))
    #expect(Line(points: ([0, 0], [10, 10])).contains([15, 15]))
}

@Test func testStandardFormSlopeIntercept() {
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
        #expect(line.slopeInterceptForm == slopeIntercept)
        if let slopeIntercept {
            #expect(line.normalized() == Line(slopeInterceptForm: slopeIntercept).normalized())
            #expect(line.slopeInterceptForm == Line(slopeInterceptForm: slopeIntercept).normalized().slopeInterceptForm)
        }
    }
}
