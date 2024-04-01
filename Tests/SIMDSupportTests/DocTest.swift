@testable import SIMDSupport
import XCTest

final class Angle_DocTests: XCTestCase {
    func test_0880dc04() throws {
        XCTAssertEqual(Angle(radians: 0.0).degrees, 0.0)
    }

    func test_0b90e805() throws {
        XCTAssertEqual(Angle(degrees: 0.0).degrees, 0.0)
        XCTAssertEqual(Angle(degrees: 360.0).radians, .pi * 2)
    }

    func test_0708105e() throws {
        XCTAssertEqual(Angle(x: 1, y: 1).degrees, 45)
    }
}

final class CoreGraphics_DocTests: XCTestCase {
    func test_07706f01() throws {
        XCTAssertEqual(CGPoint(SIMD2<Float>(1, 2)), CGPoint(x: 1, y: 2))
    }

    func test_0f808d02() throws {
        XCTAssertEqual(CGSize(SIMD2<Float>(1, 2)), CGSize(width: 1, height: 2))
    }

    func test_0e608709() throws {
        XCTAssertEqual(SIMD2<Float>(CGPoint(x: 1, y: 2)), SIMD2<Float>(1, 2))
    }

    func test_0a0f0240() throws {
        XCTAssertEqual(SIMD2<Float>(CGSize(width: 1, height: 2)), SIMD2<Float>(1, 2))
    }
}

final class SIMDSwizzling_DocTests: XCTestCase {
    func test_0a10dc0f() throws {
        XCTAssertEqual(SIMD3<Float>(1, 2, 3).xy, SIMD2<Float>(1, 2))
    }
}
