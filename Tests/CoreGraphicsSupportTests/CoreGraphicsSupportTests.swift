import CoreGraphics
import CoreGraphicsSupport
import CoreGraphicsUnsafeConformances
import Testing
import SwiftUI

@Test
func testCGSizeOperators() {
    #expect(CGSize(width: 10, height: 100) * 10 == CGSize(width: 100, height: 1000))
}


struct AngleTests {
    @Test
    func angles() {
        #expect(Angle(to: [1, 0]) == .degrees(0))
        #expect(Angle(to: [1, 1]) == .degrees(45))
        #expect(Angle(to: [0, 1]) == .degrees(90))
        #expect(Angle(to: [-1, 1]) == .degrees(135))
        #expect(Angle(to: [-1, 0]) == .degrees(180))
        #expect(Angle(to: [-1, -1]) == .degrees(-135))
        #expect(Angle(to: [0, -1]) == .degrees(-90))
        #expect(Angle(to: [1, -1]) == .degrees(-45))
        #expect(Angle(to: [0, 0]) == .degrees(0))
        #expect(Angle(to: [100, 0]) == .degrees(0))
        #expect(Angle(to: [-100, 0]) == .degrees(180))
        #expect(Angle(to: [0.707, 0.707]) == .degrees(45))
        #expect(Angle(to: [-0.707, 0.707]) == .degrees(135))
        #expect(Angle(to: [1, 1]) == Angle(to: [2, 2]))
        #expect(Angle(to: [-1, -1]) == Angle(to: [-0.5, -0.5]))

        #expect(Angle(from: [1, 1], to: [2, 1]) == .degrees(0))

        #expect(Angle(vertex: [0, 0], p1: [1, 0], p2: [0, 1]) == .degrees(90))
        #expect(Angle(vertex: [0, 0], p1: [0, 1], p2: [1, 0], clockwise: true) == .degrees(90))
    }

    @Test
    func anglesAndLengths() {
        #expect(CGPoint(0, 0).angle(to: CGPoint(1, 1)) == .degrees(45))
        #expect(CGPoint(length: CGPoint(1,1).length, angle: .degrees(45)).isApproximatelyEqual(to: [1, 1], absoluteTolerance: 1e-7))
        #expect({ var p = CGPoint(1, 1); p.length *= 2; return p }().isApproximatelyEqual(to: CGPoint(2, 2), absoluteTolerance: 1e-7))
    }

    @Test func distances() {


        #expect(CGPoint(0, 0).distance(to: CGPoint(10, 10)) == 14.142135623730951)
    }

}

extension CGPoint {
    func angle(to other: CGPoint) -> Angle {
        Angle(from: self, to: other)
    }
}
