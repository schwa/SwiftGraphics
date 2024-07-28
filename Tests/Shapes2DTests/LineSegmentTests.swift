import ApproximateEquality
import Foundation
import Testing
import CoreGraphics
@testable import Shapes2D

@Test
func testLineSegmentInitialization() throws {
    let start = CGPoint(x: 0, y: 0)
    let end = CGPoint(x: 3, y: 4)
    let segment = LineSegment(start, end)

    #expect(segment.start == start)
    #expect(segment.end == end)
}

@Test
func testLineSegmentReversed() throws {
    let start = CGPoint(x: 0, y: 0)
    let end = CGPoint(x: 3, y: 4)
    let segment = LineSegment(start, end)
    let reversed = segment.reversed

    #expect(reversed.start == segment.end)
    #expect(reversed.end == segment.start)
}

@Test
func testLineSegmentLength() throws {
    let start = CGPoint(x: 0, y: 0)
    let end = CGPoint(x: 3, y: 4)
    let segment = LineSegment(start, end)

    #expect(segment.length.isApproximatelyEqual(to: 5.0))
}

@Test
func testLineSegmentMap() throws {
    let start = CGPoint(x: 1, y: 1)
    let end = CGPoint(x: 4, y: 5)
    let segment = LineSegment(start, end)
    let mapped = segment.map { CGPoint(x: $0.x * 2, y: $0.y * 2) }

    #expect(mapped.start == CGPoint(x: 2, y: 2))
    #expect(mapped.end == CGPoint(x: 8, y: 10))
}

@Test
func testLineSegmentParallel() throws {
    let start = CGPoint(x: 0, y: 0)
    let end = CGPoint(x: 3, y: 4)
    let segment = LineSegment(start, end)
    let offset = 1.0
    let parallel = segment.parallel(offset: offset)

    // Check that the parallel segment has the same length
    #expect(segment.length.isApproximatelyEqual(to: parallel.length))

    // Check that the parallel segment is offset by the correct distance
    let midpoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
    let parallelMidpoint = CGPoint(x: (parallel.start.x + parallel.end.x) / 2,
                                   y: (parallel.start.y + parallel.end.y) / 2)

    let offsetDistance = sqrt(pow(midpoint.x - parallelMidpoint.x, 2) +
                              pow(midpoint.y - parallelMidpoint.y, 2))
    #expect(offsetDistance.isApproximatelyEqual(to: abs(offset)))

    // Check that the parallel segment is indeed parallel (same angle)
    let originalAngle = atan2(end.y - start.y, end.x - start.x)
    let parallelAngle = atan2(parallel.end.y - parallel.start.y,
                              parallel.end.x - parallel.start.x)
    #expect(originalAngle.isApproximatelyEqual(to: parallelAngle))
}

@Test
func testLineSegmentApproximateEquality() throws {
    let segment1 = LineSegment(CGPoint(x: 0, y: 0), CGPoint(x: 3, y: 4))
    let segment2 = LineSegment(CGPoint(x: 0.0001, y: -0.0001), CGPoint(x: 3.0001, y: 3.9999))

    #expect(segment1.isApproximatelyEqual(to: segment2, absoluteTolerance: 0.001))
    #expect(!segment1.isApproximatelyEqual(to: segment2, absoluteTolerance: 0.00001))
}

@Test
func testLineSegmentCodable() throws {
    let originalSegment = LineSegment(CGPoint(x: 1, y: 2), CGPoint(x: 3, y: 4))
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let encodedData = try encoder.encode(originalSegment)
    let decodedSegment = try decoder.decode(LineSegment.self, from: encodedData)

    #expect(decodedSegment == originalSegment)
}

@Test
func testLineSegmentEquatable() throws {
    let segment1 = LineSegment(CGPoint(x: 0, y: 0), CGPoint(x: 3, y: 4))
    let segment2 = LineSegment(CGPoint(x: 0, y: 0), CGPoint(x: 3, y: 4))
    let segment3 = LineSegment(CGPoint(x: 1, y: 1), CGPoint(x: 4, y: 5))

    #expect(segment1 == segment2)
    #expect(segment1 != segment3)
}
