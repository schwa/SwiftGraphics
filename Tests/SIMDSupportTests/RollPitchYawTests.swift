import Foundation
import simd
@testable import SIMDSupport
import SwiftUI
import Testing
import ApproximateEquality
import CoreGraphicsSupport

// https://www.redcrab-software.com/en/Calculator/3x3/Matrix/Rotation-Matrix
// https://www.wolframalpha.com/input?i=roll+pitch+yaw
@Test func testWorldMode() {
    let objectX = RollPitchYaw(x: .degrees(45))
    #expect(objectX.matrix3x3.isApproximatelyEqual(to: simd_float3x3(columns: (
        [1, 0, 0], [0, 0.707, 0.707], [0, -0.707, 0.707])), absoluteTolerance: 0.001))
    #expect(objectX.isApproximatelyEqual(to: RollPitchYaw(matrix: objectX.matrix3x3), absoluteTolerance: .degrees(0.001)))

    let objectY = RollPitchYaw(y: .degrees(45))
    #expect(objectY.matrix3x3.isApproximatelyEqual(to: simd_float3x3(columns: (
        [0.7071067, 0.0, -0.7071068], [0.0, 0.99999994, 0.0], [0.7071068, 0.0, 0.7071067]
    )), absoluteTolerance: 0.001))
    #expect(objectY.isApproximatelyEqual(to: RollPitchYaw(matrix: objectY.matrix3x3), absoluteTolerance: .degrees(0.001)))

    let objectZ = RollPitchYaw(z: .degrees(45))
    #expect(objectZ.matrix3x3.isApproximatelyEqual(to: simd_float3x3(columns: (
        [0.7071067, 0.7071068, 0.0], [-0.7071068, 0.7071067, 0.0], [0.0, 0.0, 1.0]
    )), absoluteTolerance: 0.001))
    #expect(objectZ.isApproximatelyEqual(to: RollPitchYaw(matrix: objectZ.matrix3x3), absoluteTolerance: .degrees(0.001)))

    let objectXYZ = RollPitchYaw(x: .degrees(10), y: .degrees(20), z: .degrees(30))
    #expect(objectXYZ.matrix3x3.isApproximatelyEqual(to: simd_float3x3(columns: (
        [0.8137976, 0.54383814, -0.20487414], [-0.46984628, 0.8231729, 0.31879574], [0.3420201, -0.16317587, 0.92541647])), absoluteTolerance: 0.001))
    #expect(objectXYZ.isApproximatelyEqual(to: RollPitchYaw(matrix: objectXYZ.matrix3x3), absoluteTolerance: .degrees(0.001)))

}


// TODO: Move to matrix
internal extension float4x4 {
    init(rotationAngle angle: Angle, axis: SIMD3<Float>) {
        let radians = Float(angle.radians)
        let c = cos(radians)
        let s = sin(radians)
        let axis = normalize(axis)
        let temp = (1 - c) * axis

        self.init(columns: (
            SIMD4<Float>(c + temp.x * axis.x,
                         temp.x * axis.y + s * axis.z,
                         temp.x * axis.z - s * axis.y,
                         0),
            SIMD4<Float>(temp.y * axis.x - s * axis.z,
                         c + temp.y * axis.y,
                         temp.y * axis.z + s * axis.x,
                         0),
            SIMD4<Float>(temp.z * axis.x + s * axis.y,
                         temp.z * axis.y - s * axis.x,
                         c + temp.z * axis.z,
                         0),
            SIMD4<Float>(0, 0, 0, 1)
        ))
    }
}
