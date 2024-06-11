import Foundation
import simd
@testable import SIMDSupport
import XCTest

class TransformTests: XCTestCase {
    func testTranslateShortcut() {
        let t1 = Transform(translation: [1, 2, 3])
        XCTAssert(t1.storage.isSRTForm)
        let m1 = t1.matrix
        var t2 = Transform(m1)
        XCTAssert(t2.storage.isMatrixForm)
        t2.translation = [10, 20, 30]
        XCTAssert(t2.storage.isMatrixForm)
    }

    func test1() {
        // Define scale, rotation (90 degrees around z-axis), and translation
        let srt = SRT(scale: [2, 2, 2], rotation: simd_quatf(angle: .degrees(90), axis: [0, 0, 1]), translation: [5, 10, 15])

        // Define a test point
        let point = SIMD4<Float>(1, 0, 0, 1)

        // Apply the transformation to the point
        let transformedPoint = srt.matrix * point

        // Expected result:
        // Scale (2, 2, 2): point becomes (2, 0, 0)
        // Rotate 90 degrees around z-axis: (2, 0, 0) becomes (0, 2, 0)
        // Translate (5, 10, 15): (0, 2, 0) becomes (5, 12, 15)
        let expectedPoint = SIMD4<Float>(5, 12, 15, 1)

        // Assert that the transformed point matches the expected point
        XCTAssertEqual(transformedPoint.x, expectedPoint.x, accuracy: 1e-5)
        XCTAssertEqual(transformedPoint.y, expectedPoint.y, accuracy: 1e-5)
        XCTAssertEqual(transformedPoint.z, expectedPoint.z, accuracy: 1e-5)
        XCTAssertEqual(transformedPoint.w, expectedPoint.w, accuracy: 1e-5)
    }
}

class TransformationTests: XCTestCase {

    // Test that the transformation follows the right-hand rule
    func testSRTTransform() {
        // Define scale, rotation (90 degrees around z-axis), and translation
        let scale = SIMD3<Float>(2, 2, 2)
        let rotationAngle: Float = .pi / 2 // 90 degrees
        let rotationAxis = SIMD3<Float>(0, 0, 1) // Rotate around z-axis
        let translation = SIMD3<Float>(5, 10, 15)

        // Create the combined transformation matrix
        let transformationMatrix = float4x4(scale: scale, rotationAngle: rotationAngle, rotationAxis: rotationAxis, translation: translation)

        // Define a test point
        let point = SIMD4<Float>(1, 0, 0, 1)

        // Apply the transformation to the point
        let transformedPoint = transformationMatrix * point

        // Expected result:
        // Scale (2, 2, 2): point becomes (2, 0, 0)
        // Rotate 90 degrees around z-axis: (2, 0, 0) becomes (0, 2, 0)
        // Translate (5, 10, 15): (0, 2, 0) becomes (5, 12, 15)
        let expectedPoint = SIMD4<Float>(5, 12, 15, 1)

        // Assert that the transformed point matches the expected point
        XCTAssertEqual(transformedPoint.x, expectedPoint.x, accuracy: 1e-5)
        XCTAssertEqual(transformedPoint.y, expectedPoint.y, accuracy: 1e-5)
        XCTAssertEqual(transformedPoint.z, expectedPoint.z, accuracy: 1e-5)
        XCTAssertEqual(transformedPoint.w, expectedPoint.w, accuracy: 1e-5)
    }
}

// Extension to float4x4 as defined previously
internal extension float4x4 {
    // Initialize a scale matrix
    init(scale s: SIMD3<Float>) {
        self.init(SIMD4<Float>(s.x, 0, 0, 0),
                  SIMD4<Float>(0, s.y, 0, 0),
                  SIMD4<Float>(0, 0, s.z, 0),
                  SIMD4<Float>(0, 0, 0, 1))
    }

    // Initialize a rotation matrix (angle in radians)
    init(rotationAngle angle: Float, axis: SIMD3<Float>) {
        let c = cos(angle)
        let s = sin(angle)
        let axis = normalize(axis)
        let temp = (1 - c) * axis

        self.init(SIMD4<Float>(c + temp.x * axis.x,
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
                  SIMD4<Float>(0, 0, 0, 1))
    }

    // Initialize a translation matrix
    init(translation t: SIMD3<Float>) {
        self.init(SIMD4<Float>(1, 0, 0, 0),
                  SIMD4<Float>(0, 1, 0, 0),
                  SIMD4<Float>(0, 0, 1, 0),
                  SIMD4<Float>(t.x, t.y, t.z, 1))
    }

    // Initialize a transformation matrix with scale, rotation, and translation
    init(scale s: SIMD3<Float>, rotationAngle angle: Float, rotationAxis axis: SIMD3<Float>, translation t: SIMD3<Float>) {
        let scaleMatrix = float4x4(scale: s)
        let rotationMatrix = float4x4(rotationAngle: angle, axis: axis)
        let translationMatrix = float4x4(translation: t)

        // Combine the transformations: T * R * S
        self = translationMatrix * rotationMatrix * scaleMatrix
    }
}
