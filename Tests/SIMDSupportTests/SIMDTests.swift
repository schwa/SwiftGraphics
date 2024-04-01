import Foundation
import simd
@testable import SIMDSupport
import XCTest

class SIMDTests: XCTestCase {
    func testVectors() {
        XCTAssertEqual(SIMD2<Float>.zero, [0, 0])
        XCTAssertEqual(SIMD2<Float>.unit, [1, 1])
        XCTAssertEqual(SIMD2<Float>(1, 0).length, 1)
        XCTAssertEqual(SIMD2<Float>(1, 1).length, 1.4142135, accuracy: .ulpOfOne)
        XCTAssertEqual(SIMD2<Float>(1, 2).map { $0 * 2 }, [2, 4])
        XCTAssertEqual(SIMD3<Float>(1, 2, 3).map { $0 * 2 }, [2, 4, 6])
        XCTAssertEqual(SIMD4<Float>(1, 2, 3, 4).map { $0 * 2 }, [2, 4, 6, 8])
        XCTAssertEqual(SIMD3<Float>(1, 2, 3).xy, [1, 2])
        XCTAssertEqual(SIMD4<Float>(1, 2, 3, 4).xy, [1, 2])
        XCTAssertEqual(SIMD4<Float>(1, 2, 3, 4).xyz, [1, 2, 3])
    }

    func testMatrix1() {
        XCTAssertEqual(simd_float3x3(truncating: simd_float4x4(diagonal: [1, 2, 3, 4])), simd_float3x3(diagonal: [1, 2, 3]))
    }

    func testMatrix2() {
        let m = simd_float4x4(diagonal: [1, 2, 3, 4])
        XCTAssertEqual(m.scalars, [1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 3, 0, 0, 0, 0, 4])
        XCTAssertEqual(m.diagonal, [1, 2, 3, 4])
    }

    func testMatrix3() {
        let m = simd_float4x4(columns: ([1, 2, 3, 4], .zero, .zero, .zero))
        XCTAssertEqual(m.scalars, [1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    }

    func testMatrixRows() {
        let m = simd_float4x4(rows: ([1, 2, 3, 4], .zero, .zero, .zero))
        XCTAssertEqual(m.scalars, [1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 4, 0, 0, 0])
    }

    func testQuat() {
        XCTAssertEqual(simd_quatf.identity, simd_quatf(angle: 0, axis: [0, 0, 0]))
        XCTAssertEqual(simd_quatf.identity, simd_quatf(angle: 0, axis: [1, 0, 0]))
        XCTAssertEqual(simd_quatf.identity, simd_quatf(angle: 0, axis: [0, 1, 0]))
        XCTAssertEqual(simd_quatf.identity, simd_quatf(angle: 0, axis: [0, 0, 1]))
    }
}

class TempTest: XCTestCase {
    func testAPI() {
        let scalars = Array(stride(from: Float(0), through: 15, by: 1))
        XCTAssertEqual(simd_float4x4(scalars: scalars).scalars, scalars)
    }
}
