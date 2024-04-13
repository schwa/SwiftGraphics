import CoreGraphicsSupport
@testable import Shapes2D
import SwiftUI
import XCTest

// final class Shapes2DTests: XCTestCase {
//    //    func testExample() throws {
//    //        func f <Element>(_ tuple: (previous: Element?, current: Element, next: Element?)?) -> [Element?]? {
//    //            tuple.map { [$0.previous, $0.current, $0.next] }
//    //        }
//    //        let values = [1,2,3,4]
//    //        var iterator = values.peekingWindow()
//    //        XCTAssertEqual(f(iterator.next()), [nil, 1, .some(2)])
//    //        XCTAssertEqual(f(iterator.next()), [.some(1), 2, .some(3)])
//    //        XCTAssertEqual(f(iterator.next()), [.some(2), 3, .some(4)])
//    //        XCTAssertEqual(f(iterator.next()), [.some(3), 4, nil])
//    //        XCTAssertEqual(f(iterator.next()), nil)
//    //        XCTAssertEqual(f(iterator.next()), nil)
//    //    }
//
//    func testLine() throws {
//        func test(line: Line, isHorizontal: Bool, isVertical: Bool, m: Double?, y0: Double?, angle: Angle, xIntercept: Double?, yIntercept: Double?) {
//            XCTAssertEqual(line.isHorizontal, isHorizontal)
//            XCTAssertEqual(line.isVertical, isVertical)
//            if let m {
//                XCTAssertEqual(line.m!, m, accuracy: 0.000_1)
//            }
//            else {
//                XCTAssertEqual(line.m, nil)
//            }
//            if let y0 {
//                XCTAssertEqual(line.y0!, y0, accuracy: 0.000_1)
//            }
//            else {
//                XCTAssertEqual(line.y0, nil)
//            }
//            XCTAssertEqual(line.angle.radians, angle.radians, accuracy: 0.000_1)
//            if let xIntercept {
//                XCTAssertEqual(line.xIntercept!, xIntercept, accuracy: 0.000_1)
//            }
//            else {
//                XCTAssertEqual(line.xIntercept, nil)
//            }
//            if let yIntercept {
//                XCTAssertEqual(line.yIntercept!, yIntercept, accuracy: 0.000_1)
//            }
//            else {
//                XCTAssertEqual(line.yIntercept, nil)
//            }
//        }
//
//        do {
//            let line = Line(points: ([0, 0], [10, 0]))
//            test(line: line, isHorizontal: true, isVertical: false, m: 0, y0: 0, angle: .degrees(0), xIntercept: nil, yIntercept: 0)
//            XCTAssertEqual(line.y(for: 0), 0)
//            XCTAssertEqual(line.y(for: 10), 0)
//        }
//        do {
//            let line = Line(points: ([0, 0], [10, 10]))
//            test(line: line, isHorizontal: false, isVertical: false, m: 1, y0: 0, angle: .degrees(45), xIntercept: 0, yIntercept: 0)
//            XCTAssertEqual(line.y(for: 0), 0)
//            XCTAssertEqual(line.y(for: 10), 10)
//        }
//        do {
//            let line = Line(points: ([0, 0], [0, 10]))
//            test(line: line, isHorizontal: false, isVertical: true, m: nil, y0: nil, angle: .degrees(90), xIntercept: 0, yIntercept: nil)
//            XCTAssertEqual(line.y(for: 0), nil)
//            XCTAssertEqual(line.y(for: 10), nil)
//        }
//        do {
//            let line = Line(points: ([77, 182], [-42, 13]))
//            test(line: line, isHorizontal: false, isVertical: false, m: 1.420168, y0: 72.647, angle: .degrees(54.84901), xIntercept: -51.1538, yIntercept: 72.647)
//            XCTAssertEqual(line.y(for: 0)!, 72.647, accuracy: 0.000_1)
//            XCTAssertEqual(line.y(for: 10)!, 86.8487, accuracy: 0.000_1)
//        }
//
//        do {
//            // TODO: FIXME
////            let line1 = Line(point: [0, 0], angle: .degrees(45))
////            let line2 = LineSegment(0, 0, 10, 10).line
////            XCTAssertEqual(line1, line2)
//        }
//    }
//
//    func testLineCompare() {
//        do {
//            let line = Line(points: ([0, 0], [0, 10]))
//            XCTAssertEqual(line.isVertical, true)
//            XCTAssertEqual(line.compare(point: [-10, 0]), .orderedDescending)
//            XCTAssertEqual(line.compare(point: [0, 0]), .orderedSame)
//            XCTAssertEqual(line.compare(point: [10, 0]), .orderedAscending)
//        }
//        do {
//            let line = Line(points: ([0, 0], [10, 0]))
//            XCTAssertEqual(line.isHorizontal, true)
//            XCTAssertEqual(line.compare(point: [0, -10]), .orderedDescending)
//            XCTAssertEqual(line.compare(point: [0, 0]), .orderedSame)
//            XCTAssertEqual(line.compare(point: [0, 10]), .orderedAscending)
//        }
//        do {
//            let line = Line(points: ([0, 0], [10, 10]))
//            XCTAssertEqual(line.compare(point: [0, 10]), .orderedAscending)
//            XCTAssertEqual(line.compare(point: [0, 0]), .orderedSame)
//            XCTAssertEqual(line.compare(point: [10, 0]), .orderedDescending)
//        }
//    }
//
//    func testLineIntersectsRect() {
//        let size = CGSize(100, 100)
//
//        let bounds = CGRect(origin: CGPoint(1, 1) * CGPoint(100, 100), size: size)
//        let above = bounds.midXMaxY + [0, 10]
//        let below = bounds.midXMinY + [0, -10]
//        let left = bounds.minXMidY + [-10, 0]
//        let right = bounds.maxXMidY + [10, 0]
//
//        let segments = [
//            (above, below), (left, right),
//            (above, left), (above, right),
//            (below, left), (below, right),
//            (below, above), (right, left),
//            (left, above), (right, above),
//            (left, below), (right, below),
//            (above, above), (above, above), // Should be outside
//        ]
//        .map { (start, end) in
//            LineSegment(start, end)
//        }
//
//        var svg = DumbSVGGenerator()
//        svg.add(bounds, stroke: "#DDDDDD")
//        for segment in segments {
//            svg.add(segment, color: "red")
//            if let result = segment.line.lineSegment(bounds: bounds) {
//                svg.add(result, color: "blue", arrow: true)
//            }
//        }
//        print(svg)
//        try! svg.description.write(to: URL(filePath: "/tmp/test.svg"), atomically: true, encoding: .utf8)
//
////        XCTAssertEqual(segment.line.lineSegment(bounds: bounds), LineSegment([100, 140], [140, 100]))
////        XCTAssertEqual(segment.line.lineSegment(bounds: bounds)?.reversed, LineSegment([140, 100], [100, 140]))
//    }
// }
//
// extension ComparisonResult: CustomStringConvertible {
//    public var description: String {
//        switch self {
//        case .orderedAscending:
//            "orderedAscending"
//        case .orderedDescending:
//            "orderedDescending"
//        case .orderedSame:
//            "orderedSame"
//        }
//    }
// }
