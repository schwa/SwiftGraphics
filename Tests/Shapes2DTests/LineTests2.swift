import ApproximateEquality
import Testing
import CoreGraphics
@testable import Shapes2D
import SwiftUI

@Test
func testLineInitialization() throws {
    let line = Line(a: 1, b: 2, c: 3)
    #expect(line.a == 1)
    #expect(line.b == 2)
    #expect(line.c == 3)
}

@Test
func testHorizontalLine() throws {
    let line = Line.horizontal(y: 5)
    #expect(line.a == 0)
    #expect(line.b == 1)
    #expect(line.c == -5)
    #expect(line.isHorizontal)
    #expect(!line.isVertical)
}

@Test
func testVerticalLine() throws {
    let line = Line.vertical(x: 3)
    #expect(line.a == 1)
    #expect(line.b == 0)
    #expect(line.c == 3)
    #expect(!line.isHorizontal)
    #expect(line.isVertical)
}

@Test
func testXForY() throws {
    let line = Line(a: 2, b: -1, c: 4)
    let x = line.x(forY: 3)
    #expect(x != nil)
    #expect(x!.isApproximatelyEqual(to: 3.5))
}

@Test
func testYForX() throws {
    let line = Line(a: 2, b: -1, c: 4)
    let y = line.y(forX: 5)
    #expect(y != nil)
    #expect(y!.isApproximatelyEqual(to: 6))
}

@Test
func testIntercepts() throws {
    let line = Line(a: 2, b: -1, c: 4)

    let xIntercept = line.xIntercept
    #expect(xIntercept != nil)
    #expect(xIntercept!.x.isApproximatelyEqual(to: 2))
    #expect(xIntercept!.y.isApproximatelyEqual(to: 0))

    let yIntercept = line.yIntercept
    #expect(yIntercept != nil)
    #expect(yIntercept!.x.isApproximatelyEqual(to: 0))
    #expect(yIntercept!.y.isApproximatelyEqual(to: -4))
}

@Test
func testSlope() throws {
    let line = Line(a: 2, b: -1, c: 4)
    #expect(line.slope.isApproximatelyEqual(to: 2))
}

@Test
func testInitWithPoints() throws {
    let line = Line(points: (CGPoint(x: 0, y: 0), CGPoint(x: 3, y: 4)))
    #expect(line.slope.isApproximatelyEqual(to: 4.0/3.0))
    #expect(line.contains(CGPoint(x: 0, y: 0)))
    #expect(line.contains(CGPoint(x: 3, y: 4)))
}

@Test
func testInitWithPointAndAngle() throws {
    let line = Line(point: CGPoint(x: 1, y: 1), angle: Angle(degrees: 45))
    #expect(line.slope.isApproximatelyEqual(to: 1))
    #expect(line.contains(CGPoint(x: 1, y: 1)))
}

//@Test
//func testNormalized() throws {
//    let line = Line(a: 2, b: -1, c: 4)
//    let normalized = line.normalized()
//    print(normalized)
////    #expect(isApproximatelyEqual(normalized.b, -1))
////    #expect(isApproximatelyEqual(normalized.a, -2))
////    #expect(isApproximatelyEqual(normalized.c, -4))
//}

@Test
func testDistanceToPoint() throws {
    let line = Line(a: 3, b: -4, c: 5)
    let point = CGPoint(x: 2, y: 1)
    let distance = line.distance(to: point)
    #expect(distance == 0.6)
}

@Test
func testContainsPoint() throws {
    let line = Line(a: 3, b: -4, c: 5)
    let pointOn = CGPoint(x: 5, y: 2.5)
    let pointOff = CGPoint(x: 2, y: 1)
    #expect(line.contains(pointOn))
    #expect(!line.contains(pointOff, tolerance: 1e-6))
}

@Test
func testLineAngleHorizontal() throws {
    let line = Line(a: 0, b: 1, c: 0)
    #expect(line.angle.degrees.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-6))
}

@Test
func testLineAngleVertical() throws {
    let line = Line(a: 1, b: 0, c: 0)
    #expect(line.angle.degrees.isApproximatelyEqual(to: -90, absoluteTolerance: 1e-6))
}

@Test
func testLineAngle45Degrees() throws {
    let line = Line(a: 1, b: -1, c: 0)
    #expect(line.angle.degrees.isApproximatelyEqual(to: 45, absoluteTolerance: 1e-6))
}

@Test
func testLineAngleNegative45Degrees() throws {
    let line = Line(a: 1, b: 1, c: 0)
    #expect(line.angle.degrees.isApproximatelyEqual(to: -45, absoluteTolerance: 1e-6))
}

@Test
func testLineAngle30Degrees() throws {
    let line = Line(a: sqrt(3), b: -1, c: 0)
    #expect(line.angle.degrees.isApproximatelyEqual(to: 60, absoluteTolerance: 1e-6))
}

@Test
func testLineAngle60Degrees() throws {
    let line = Line(a: 1, b: -sqrt(3), c: 0)
    #expect(line.angle.degrees.isApproximatelyEqual(to: 30, absoluteTolerance: 1e-6))
}

@Test
func testLineAngleWithTranslation() throws {
    let line = Line(a: 1, b: -1, c: 5) // y = x + 5
    #expect(line.angle.degrees.isApproximatelyEqual(to: 45, absoluteTolerance: 1e-6))
}

@Test
func testLineAngleConsistencyWithSlope() throws {
    let line = Line(a: 2, b: -3, c: 1)
    let angleFromSlope = Angle(radians: atan(line.slope))
    #expect(line.angle.radians.isApproximatelyEqual(to: angleFromSlope.radians, absoluteTolerance: 1e-6))
}
