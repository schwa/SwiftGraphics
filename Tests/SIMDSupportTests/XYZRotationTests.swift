import Foundation
import simd
@testable import SIMDSupport
import SwiftUI
import Testing

struct XYZRotationTests {
    let tolerance: Float = 1e-5

    // https://www.redcrab-software.com/en/Calculator/3x3/Matrix/Rotation-Matrix
    // https://www.wolframalpha.com/input?i=roll+pitch+yaw

    @Test(arguments: [
        (XYZRotation(), simd_float3x3([[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]])),
        (XYZRotation(x: .degrees(45)), simd_float3x3([[1.0, 0.0, 0.0], [0.0, 0.70710677, 0.70710677], [0.0, -0.70710677, 0.70710677]])),
        (XYZRotation(y: .degrees(45)), simd_float3x3([[0.70710677, 0.0, -0.70710677], [0.0, 1.0, 0.0], [0.70710677, 0.0, 0.70710677]])),
        (XYZRotation(z: .degrees(45)), simd_float3x3([0.7071067, 0.7071068, 0.0], [-0.7071068, 0.7071067, 0.0], [0.0, 0.0, 1.0])),
        (XYZRotation(x: .degrees(10), y: .degrees(20), z: .degrees(30)), simd_float3x3([0.8137976, 0.54383814, -0.20487414], [-0.46984628, 0.8231729, 0.31879574], [0.3420201, -0.16317587, 0.92541647])),
    ])
    func testBasic(rotation: XYZRotation, matrix: simd_float3x3) {
        let result2 = rotation.toMatrix3x3(order: .zyx)
        #expect(result2.isApproximatelyEqual(to: matrix, absoluteTolerance: tolerance))
    }

    @Test
    func xRotation() {
        let angle = Angle(degrees: 45) // 45 degrees
        let rotation = XYZRotation(x: angle, y: Angle(radians: 0), z: Angle(radians: 0))
        let expected = simd_float3x3(
            simd_float3(1, 0, 0),
            simd_float3(0, Float(cos(angle.radians)), Float(sin(angle.radians))),
            simd_float3(0, Float(-sin(angle.radians)), Float(cos(angle.radians)))
        )

        for order in XYZRotation.Order.allCases {
            let result = rotation.toMatrix3x3(order: order)
            #expect(result.isApproximatelyEqual(to: expected, absoluteTolerance: tolerance))
        }
    }

    @Test
    func yRotation() {
        let angle = Angle(degrees: 60) // 60 degrees
        let rotation = XYZRotation(x: Angle(radians: 0), y: angle, z: Angle(radians: 0))
        let expected = simd_float3x3(
            simd_float3(Float(cos(angle.radians)), 0, Float(-sin(angle.radians))),
            simd_float3(0, 1, 0),
            simd_float3(Float(sin(angle.radians)), 0, Float(cos(angle.radians)))
        )

        for order in XYZRotation.Order.allCases {
            let result = rotation.toMatrix3x3(order: order)
            #expect(result.isApproximatelyEqual(to: expected, absoluteTolerance: tolerance))
        }
    }

    @Test
    func zRotation() {
        let angle = Angle(degrees: 30) // 30 degrees
        let rotation = XYZRotation(x: Angle(radians: 0), y: Angle(radians: 0), z: angle)
        let expected = simd_float3x3(
            simd_float3(Float(cos(angle.radians)), Float(sin(angle.radians)), 0),
            simd_float3(Float(-sin(angle.radians)), Float(cos(angle.radians)), 0),
            simd_float3(0, 0, 1)
        )

        for order in XYZRotation.Order.allCases {
            let result = rotation.toMatrix3x3(order: order)
            #expect(result.isApproximatelyEqual(to: expected, absoluteTolerance: tolerance))
        }
    }

    @Test
    func compositeRotation() {
        let rotation = XYZRotation(x: Angle(degrees: 45), y: Angle(degrees: 60), z: Angle(degrees: 30))

        // Test each order
        let ordersAndExpected: [(XYZRotation.Order, simd_float3x3)] = [
            (.xyz, simd_float3x3([[0.43301263, 0.24999997, -0.86602527], [0.17677677, 0.9185586, 0.35355338], [0.8838835, -0.3061863, 0.35355332]])),
            (.xzy, simd_float3x3([[0.43301266, 0.5, -0.75], [0.43559578, 0.6123724, 0.6597396], [0.7891491, -0.6123724, 0.047367133]])),
            (.yxz, simd_float3x3([[0.12682644, 0.78033006, -0.61237246], [-0.35355338, 0.6123724, 0.70710677], [0.9267767, 0.12682654, 0.35355335]])),
            (.yzx, simd_float3x3([[0.43301266, 0.7891491, -0.43559578], [-0.5, 0.6123724, 0.6123724], [0.75, -0.047367133, 0.6597396]])),
            (.zxy, simd_float3x3([[0.7391989, 0.35355338, -0.57322335], [0.28033012, 0.6123724, 0.7391989], [0.61237246, -0.70710677, 0.35355335]])),
            (.zyx, simd_float3x3([[0.43301266, 0.8838835, -0.17677674], [-0.24999999, 0.3061862, 0.91855866], [0.86602545, -0.35355335, 0.35355335]])),
        ]
        for (order, expected) in ordersAndExpected {
            let result = rotation.toMatrix3x3(order: order)
            #expect(result.isApproximatelyEqual(to: expected, absoluteTolerance: tolerance), "Failed for order: \(order)")
        }
    }

    @Test(arguments: [
        (Angle(degrees: 0), SIMD3<Float>(1, 0, 0)),
        (Angle(degrees: 0), SIMD3<Float>(0, 1, 0)),
        (Angle(degrees: 0), SIMD3<Float>(0, 0, 1)),
        (Angle(degrees: 45), SIMD3<Float>(1, 0, 0)),
        (Angle(degrees: 45), SIMD3<Float>(0, 1, 0)),
        (Angle(degrees: 45), SIMD3<Float>(0, 0, 1)),
        (Angle(degrees: 225), SIMD3<Float>(1, 0, 0)),
        (Angle(degrees: 225), SIMD3<Float>(0, 1, 0)),
        (Angle(degrees: 225), SIMD3<Float>(0, 0, 1))
    ])
    func testMatrixRotation(angle: Angle, axis: SIMD3<Float>) {
        let viaMatrix = simd_float3x3(rotationAngle: angle, axis: axis)
        let viaQuaternion = simd_float3x3(simd_quaternion(Float(angle.radians), axis))
        #expect(viaMatrix.isApproximatelyEqual(to: viaQuaternion, absoluteTolerance: 1e-7))
    }
}