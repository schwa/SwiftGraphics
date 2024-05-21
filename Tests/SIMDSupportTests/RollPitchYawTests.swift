import Foundation
import simd
@testable import SIMDSupport
import XCTest

class RollPitchYawTests: XCTestCase {
    func testQuaternions() throws {
        throw XCTSkip("Currently disabled.")
        let rpy = RollPitchYaw(roll: .degrees(0.1), pitch: .degrees(0.2), yaw: .degrees(0.3))
        let q = rpy.quaternion_direct
        let rpy2 = RollPitchYaw(quaternion: q)
        XCTAssertEqual(rpy.quaternion, rpy2.quaternion, accuracy: 0.01)
    }

    func testAddition() throws {
        let a = RollPitchYaw(roll: .degrees(0.1), pitch: .degrees(0.2), yaw: .degrees(0.3))
        let b = RollPitchYaw(roll: .degrees(0.11), pitch: .degrees(0.13), yaw: .degrees(0.17))
        let c = a + b

        let q = a.quaternion * b.quaternion

        XCTAssertEqual(c.quaternion, q, accuracy: 0.01)
    }
}
