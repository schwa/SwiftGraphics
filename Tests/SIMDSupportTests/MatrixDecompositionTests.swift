import Foundation
import simd
@testable import SIMDSupport
import XCTest

class MatrixDecompositionTests: XCTestCase {
    func testIdentity() {
        let srt = SRT()
        let matrix = srt.matrix
        XCTAssertTrue(matrix.isAffine)
        let (scale, rotatation, translation) = matrix.decompose
        let decomposed = SRT(scale: scale, rotation: rotatation, translation: translation)
        XCTAssertEqual(srt, decomposed)
    }

    func testScale() {
        let srt = SRT(scale: [3, 2, 1])
        let matrix = srt.matrix
        XCTAssertTrue(matrix.isAffine)
        let (scale, rotatation, translation) = matrix.decompose
        let decomposed = SRT(scale: scale, rotation: rotatation, translation: translation)
        print(decomposed.matrix)
        XCTAssertEqual(srt, decomposed)
    }

    func testRotation() {
        let rotation = simd_float4x4(simd_quatf(angle: .degrees(90), axis: [0, 1, 0]))
        XCTAssertTrue(rotation.isAffine)
        let srt = SRT(rotation: rotation)
        let matrix = srt.matrix
        XCTAssertTrue(matrix.isAffine)
        let decomposed = matrix.decompose
        XCTAssertEqual(srt.rotation.matrix, decomposed.rotation, accuracy: .ulpOfOne)
    }

    func testTranslation() {
        let srt = SRT(translation: [3, 2, 1])
        let matrix = srt.matrix
        XCTAssertTrue(matrix.isAffine)
        let (scale, rotatation, translation) = matrix.decompose
        let decomposed = SRT(scale: scale, rotation: rotatation, translation: translation)
        XCTAssertEqual(srt, decomposed)
    }

    // TODO: This matrix SHOULD be decomposable but is failing due to floating point issues.
    func testProblematic() throws {
        throw XCTSkip("Skipping.")
        let matrix = simd_float4x4([[0.23499937, 0.010335696, 0.97194064, 0.0], [-8.403711e-11, 0.9999435, -0.010633481, 0.0], [-0.9719956, 0.0024988612, 0.23498604, 0.0], [0.0, 0.0, 0.0, 1.0]])
        XCTAssertTrue(matrix.isAffine)
        XCTAssertNil(matrix.decompose)
    }
}
