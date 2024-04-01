import XCTest

import earcut

class EarcutTests: XCTestCase {
    func testEarcut() {
        let indices = earcut(polygons: [[[0, 0], [100, 0], [100, 100], [0, 100]]])
        XCTAssertEqual(indices, [2, 3, 0, 0, 1, 2])
    }
}
