//import Foundation
//import simd
//@testable import SIMDSupport
//import XCTest
//
//class EulerTests: XCTestCase {
//    func testRoll() throws {
//        let e1 = Euler<Float>(roll: degreesToRadians(90))
//        XCTAssertEqual(e1.roll, degreesToRadians(90))
//        XCTAssertEqual(e1.pitch, 0)
//        XCTAssertEqual(e1.yaw, 0)
//        let q1 = simd_quatf(angle: degreesToRadians(90), axis: [1, 0, 0])
//        XCTAssertEqual(simd_quatf(e1), q1)
//        let e2 = Euler<Float>(q1)
//        XCTAssertEqual(e1, e2, accuracy: 0.001)
//    }
//
//    func testPitch() throws {
//        let e1 = Euler<Float>(pitch: degreesToRadians(90))
//        XCTAssertEqual(e1.roll, 0)
//        XCTAssertEqual(e1.pitch, degreesToRadians(90))
//        XCTAssertEqual(e1.yaw, 0)
//        let q1 = simd_quatf(angle: degreesToRadians(90), axis: [0, 1, 0])
//        XCTAssertEqual(simd_quatf(e1), q1)
//        let e2 = Euler<Float>(q1)
//        XCTAssertEqual(e1, e2, accuracy: 0.001)
//    }
//
//    func testYaw() throws {
//        let e1 = Euler<Float>(yaw: degreesToRadians(90))
//        XCTAssertEqual(e1.roll, 0)
//        XCTAssertEqual(e1.pitch, 0)
//        XCTAssertEqual(e1.yaw, degreesToRadians(90))
//        let q1 = simd_quatf(angle: degreesToRadians(90), axis: [0, 0, 1])
//        XCTAssertEqual(simd_quatf(e1), q1)
//        let e2 = Euler<Float>(q1)
//        XCTAssertEqual(e1, e2, accuracy: 0.001)
//    }
//
//    func testArithmetric() throws {
//        let e1 = Euler<Float>(roll: 1, pitch: 2, yaw: 3) + .identity
//        XCTAssertEqual(e1, Euler<Float>(roll: 1, pitch: 2, yaw: 3))
//        XCTAssertEqual(e1 + e1, Euler<Float>(roll: 2, pitch: 4, yaw: 6))
//    }
//}
