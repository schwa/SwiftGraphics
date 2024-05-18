import Foundation
import simd
@testable import SIMDSupport
import XCTest

class RotationTests: XCTestCase {
    func testMatrixInitialization() {
        let matrix = simd_float4x4(SIMD4<Float>(1, 0, 0, 0), SIMD4<Float>(0, 1, 0, 0), SIMD4<Float>(0, 0, 1, 0), SIMD4<Float>(0, 0, 0, 1))
        let rotation = Rotation(matrix: matrix)
        XCTAssertEqual(rotation.matrix, matrix)
    }

    func testQuaternionInitialization() {
        let quaternion = simd_quatf(angle: .pi / 4, axis: SIMD3<Float>(0, 0, 1))
        let rotation = Rotation(quaternion: quaternion)
        XCTAssertEqual(rotation.quaternion, quaternion)
    }

    func testRollPitchYawInitialization() {
        let rollPitchYaw = RollPitchYaw(roll: .radians(.pi / 2), pitch: .radians(.pi / 4), yaw: .radians(.pi))
        let rotation = Rotation(rollPitchYaw: rollPitchYaw)
        XCTAssertEqual(rotation.rollPitchYaw, rollPitchYaw)
    }

    func testEqualityOfDifferentStorages() {
        let matrix = simd_float4x4(SIMD4<Float>(1, 0, 0, 0), SIMD4<Float>(0, 1, 0, 0), SIMD4<Float>(0, 0, 1, 0), SIMD4<Float>(0, 0, 0, 1))
        let rotation1 = Rotation(matrix: matrix)
        let rotation2 = Rotation(matrix: matrix)
        XCTAssertEqual(rotation1, rotation2)
    }

    func testMatrixProperty() {
        let quaternion = simd_quatf(angle: .pi / 4, axis: SIMD3<Float>(0, 0, 1))
        let matrix = simd_float4x4(quaternion)
        XCTAssertEqual(Rotation.matrix(matrix), Rotation.quaternion(quaternion))
    }

    func testIdentityRotation() {
        let identityMatrix = simd_float4x4(SIMD4<Float>(1, 0, 0, 0), SIMD4<Float>(0, 1, 0, 0), SIMD4<Float>(0, 0, 1, 0), SIMD4<Float>(0, 0, 0, 1))
        XCTAssertEqual(Rotation.identity.matrix, identityMatrix)
    }
}
