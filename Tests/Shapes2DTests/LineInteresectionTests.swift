import Testing
import CoreGraphics
@testable import Shapes2D

@Test
func testLineSegmentIntersectionNone() throws {
    let segment1 = LineSegment(CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1))
    let segment2 = LineSegment(CGPoint(x: 0, y: 2), CGPoint(x: 1, y: 3))

    let intersection = LineSegment.intersection(segment1, segment2)

    #expect(intersection == .none)
}

@Test
func testLineSegmentIntersectionPoint() throws {
    let segment1 = LineSegment(CGPoint(x: 0, y: 0), CGPoint(x: 2, y: 2))
    let segment2 = LineSegment(CGPoint(x: 0, y: 2), CGPoint(x: 2, y: 0))

    let intersection = LineSegment.intersection(segment1, segment2)

    guard case let .point(intersectionPoint) = intersection else {
        Issue.record()
        return
    }

    #expect(intersectionPoint.isApproximatelyEqual(to: CGPoint(x: 1, y: 1), absoluteTolerance: 0.0001))
}

@Test
func testLineSegmentIntersectionEverywhere() throws {
    let segment1 = LineSegment(CGPoint(x: 0, y: 0), CGPoint(x: 2, y: 2))
    let segment2 = LineSegment(CGPoint(x: 1, y: 1), CGPoint(x: 3, y: 3))

    let intersection = LineSegment.intersection(segment1, segment2)

    #expect(intersection == .everywhere)
}

@Test
func testLineSegmentIntersectionTouchingEndpoints() throws {
    let segment1 = LineSegment(CGPoint(x: 0, y: 0), CGPoint(x: 2, y: 2))
    let segment2 = LineSegment(CGPoint(x: 2, y: 2), CGPoint(x: 4, y: 0))

    let intersection = LineSegment.intersection(segment1, segment2)

    guard case let .point(intersectionPoint) = intersection else {
        Issue.record()
        return
    }

    #expect(intersectionPoint.isApproximatelyEqual(to: CGPoint(x: 2, y: 2), absoluteTolerance: 0.0001))
}

@Test
func testLineSegmentIntersectionParallelNotOverlapping() throws {
    let segment1 = LineSegment(CGPoint(x: 0, y: 0), CGPoint(x: 2, y: 2))
    let segment2 = LineSegment(CGPoint(x: 0, y: 1), CGPoint(x: 2, y: 3))

    let intersection = LineSegment.intersection(segment1, segment2)

    #expect(intersection == .none)
}

@Test
func testLineSegmentIntersectionPerpendicularNotTouching() throws {
    let segment1 = LineSegment(CGPoint(x: 0, y: 0), CGPoint(x: 2, y: 0))
    let segment2 = LineSegment(CGPoint(x: 3, y: -1), CGPoint(x: 3, y: 1))

    let intersection = LineSegment.intersection(segment1, segment2)

    #expect(intersection == .none)
}

@Test
func testVerticalLinesNonOverlapping() throws {
    let segment1 = LineSegment(CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 2))
    let segment2 = LineSegment(CGPoint(x: 2, y: 0), CGPoint(x: 2, y: 2))

    let intersection = LineSegment.intersection(segment1, segment2)

    #expect(intersection == .none)
}

@Test
func testVerticalLinesOverlappingPartially() throws {
    let segment1 = LineSegment(CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 3))
    let segment2 = LineSegment(CGPoint(x: 1, y: 2), CGPoint(x: 1, y: 4))

    let intersection = LineSegment.intersection(segment1, segment2)

    #expect(intersection == .everywhere)
}

@Test
func testVerticalLinesOverlappingCompletely() throws {
    let segment1 = LineSegment(CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 2))
    let segment2 = LineSegment(CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 2))

    let intersection = LineSegment.intersection(segment1, segment2)

    #expect(intersection == .everywhere)
}

@Test
func testVerticalLineIntersectingDiagonalLine() throws {
    let vertical = LineSegment(CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 2))
    let diagonal = LineSegment(CGPoint(x: 0, y: 0), CGPoint(x: 2, y: 2))

    let intersection = LineSegment.intersection(vertical, diagonal)

    guard case let .point(intersectionPoint) = intersection else {
        Issue.record()
        return
    }

    #expect(intersectionPoint.isApproximatelyEqual(to: CGPoint(x: 1, y: 1), absoluteTolerance: 1e-6))
}

@Test
func testVerticalLineNotIntersectingDiagonalLine() throws {
    let vertical = LineSegment(CGPoint(x: 3, y: 0), CGPoint(x: 3, y: 2))
    let diagonal = LineSegment(CGPoint(x: 0, y: 0), CGPoint(x: 2, y: 2))

    let intersection = LineSegment.intersection(vertical, diagonal)

    #expect(intersection == .none)
}

@Test
func testVerticalLineTouchingDiagonalLineEndpoint() throws {
    let vertical = LineSegment(CGPoint(x: 2, y: 1), CGPoint(x: 2, y: 3))
    let diagonal = LineSegment(CGPoint(x: 0, y: 0), CGPoint(x: 2, y: 2))

    let intersection = LineSegment.intersection(vertical, diagonal)

    guard case let .point(intersectionPoint) = intersection else {
        Issue.record()
        return
    }

    #expect(intersectionPoint.isApproximatelyEqual(to: CGPoint(x: 2, y: 2), absoluteTolerance: 1e-6))
}

@Test
func testVerticalLineOverlappingVerticalPartOfDiagonalLine() throws {
    let vertical = LineSegment(CGPoint(x: 2, y: 1), CGPoint(x: 2, y: 3))
    let diagonal = LineSegment(CGPoint(x: 2, y: 2), CGPoint(x: 4, y: 2))

    let intersection = LineSegment.intersection(vertical, diagonal)

    guard case let .point(intersectionPoint) = intersection else {
        Issue.record()
        return
    }

    #expect(intersectionPoint.isApproximatelyEqual(to: CGPoint(x: 2, y: 2), absoluteTolerance: 1e-6))
}
