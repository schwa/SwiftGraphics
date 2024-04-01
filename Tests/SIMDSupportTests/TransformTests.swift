import Foundation
import simd
@testable import SIMDSupport
import XCTest

class TransformTests: XCTestCase {
    func testTransforms() {
        XCTAssertEqual("\(Transform())", "Transform(.identity)")
        XCTAssertEqual("\(Transform(scale: [3, 2, 1]))", "Transform(scale: [3, 2, 1])")
        XCTAssertEqual("\(Transform(rotation: .init(real: 1, imag: [2, 3, 4])))", "Transform(rotation: 1, [2, 3, 4])")
        XCTAssertEqual("\(Transform(translation: [1, 2, 3]))", "Transform(translation: [1, 2, 3])")
    }

    func testCodable() {
        let transforms = [
            Transform(),
            Transform(scale: [3, 2, 1]),
            Transform(rotation: .init(real: 1, imag: [2, 3, 4])),
            Transform(translation: [1, 2, 3]),
        ]
        for transform in transforms {
            let data = try! JSONEncoder().encode(transform)
            let decoded = try! JSONDecoder().decode(Transform.self, from: data)
            XCTAssertEqual(transform, decoded)
        }
    }

    func testTranslateShortcut() {
        let t1 = Transform(translation: [1, 2, 3])
        XCTAssert(t1.storage.isSRTForm)
        let m1 = t1.matrix
        var t2 = Transform(m1)
        XCTAssert(t2.storage.isMatrixForm)
        t2.translation = [10, 20, 30]
        XCTAssert(t2.storage.isMatrixForm)
    }
}
