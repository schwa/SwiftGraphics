import LegacyGraphics
import XCTest

// TODO: FIXME
// class PointTests: XCTestCase {
//     func test1() {
//         var p = CGPoint(10, 10)
//         p *= 2
//         XCTAssertEqual(p, [20, 20])
//     }

//     func test2() {
//         let p = CGPoint(length: 10, angle: degreesToRadians(90))
//             .map {
//                 $0.rounded()
//             }
//         XCTAssertEqual(p, [0, 10])
//         XCTAssertEqual(p.length, 10)
//         XCTAssertEqual(radiansToDegrees(p.angle).rounded(), 90)
//         XCTAssertEqual(p.orthogonal, [-10, 0])
//         XCTAssertEqual(p.transposed, [10, 0])
//     }

//     func testDotProduct() {
//         let a = CGPoint(1000, 0).normalized
//         let b = CGPoint(0, 100).normalized
//         let c = CGPoint(-10, 0).normalized
//         XCTAssertEqual(dotProduct(a, b), a ⋅ b)
//         XCTAssertEqual(dotProduct(a, c), a ⋅ c)
//         XCTAssertEqual(dotProduct(a, b), 0)
//         XCTAssertEqual(dotProduct(a, c), -1)
//     }

//     func testCrossproduct() {
//         let a = CGPoint(1000, 0).normalized
//         let b = CGPoint(0, 100).normalized
//         let c = CGPoint(-10, 0).normalized
//         XCTAssertEqual(crossProduct(a, b), a ⨉ b)
//         XCTAssertEqual(crossProduct(a, c), a ⨉ c)
//         XCTAssertEqual(crossProduct(a, b), 1)
//         XCTAssertEqual(crossProduct(a, c), -0)

//         XCTAssertEqual(crossProduct(a, b), perpProduct(a, b))
//         XCTAssertEqual(crossProduct(a, c), perpProduct(a, c))
//     }
// }
