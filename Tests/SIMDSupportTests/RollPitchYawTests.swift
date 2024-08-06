import Foundation
import simd
@testable import SIMDSupport
import SwiftUI
import Testing

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

struct XYZRotationTests {
    let tolerance: Float = 1e-6

    @Test
    func identityRotation() {
        let rotation = XYZRotation(x: Angle(radians: 0), y: Angle(radians: 0), z: Angle(radians: 0))
        let identity = simd_float3x3(1)

        for order in XYZRotation.Order.allCases {
            let result = rotation.toMatrix3x3(order: order)
            #expect(result.isApproximatelyEqual(to: identity, absoluteTolerance: tolerance))
        }
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
            (.xyz, simd_float3x3(simd_float3(0.433012702, 0.62499994, -0.65000004),
                                 simd_float3(-0.2165063, 0.86602545, 0.4504857),
                                 simd_float3(0.8749998, -0.21650632, 0.43301263))),
            (.xzy, simd_float3x3(simd_float3(0.433012702, 0.5, -0.7499999),
                                 simd_float3(-0.43301263, 0.86602545, 0.25000006),
                                 simd_float3(0.7905693, -0.0, 0.61237246))),
            (.yxz, simd_float3x3(simd_float3(0.433012702, 0.7905693, -0.43301263),
                                 simd_float3(-0.2165063, 0.61237246, 0.7905693),
                                 simd_float3(0.8749998, -0.0, 0.4330127))),
            (.yzx, simd_float3x3(simd_float3(0.433012702, 0.35355335, -0.8291796),
                                 simd_float3(-0.612372, 0.86602545, 0.0),
                                 simd_float3(0.6614378, 0.35355335, 0.55901706))),
            (.zxy, simd_float3x3(simd_float3(0.433012702, 0.5, -0.7499999),
                                 simd_float3(-0.7905693, 0.61237246, -0.0),
                                 simd_float3(0.43301263, 0.61237246, 0.6614378))),
            (.zyx, simd_float3x3(simd_float3(0.433012702, 0.7499999, -0.5),
                                 simd_float3(-0.7905693, 0.4330127, 0.43301263),
                                 simd_float3(0.43301263, 0.5, 0.7499999)))
        ]

        for (order, expected) in ordersAndExpected {
            let result = rotation.toMatrix3x3(order: order)
            #expect(result.isApproximatelyEqual(to: expected, absoluteTolerance: tolerance), "Failed for order: \(order)")
        }
    }
}

extension simd_float3x3 {
    func isApproximatelyEqual(to other: simd_float3x3, absoluteTolerance tolerance: Float) -> Bool {
        for i in 0..<3 {
            for j in 0..<3 {
                if abs(self[i][j] - other[i][j]) > tolerance {
                    return false
                }
            }
        }
        return true
    }
}
