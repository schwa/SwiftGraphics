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
}
