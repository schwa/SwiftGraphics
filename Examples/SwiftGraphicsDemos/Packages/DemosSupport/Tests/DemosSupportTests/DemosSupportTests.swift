import XCTest
@testable import DemosSupport

final class SpatialLookupTests: XCTestCase {
    func test1() throws {
        var table = SpatialLookupTable<[SIMD2<Float>]>(size: [100, 100], positions: [])
        table.update(points: [
            [0, 0], [100, 100]
        ], radius: 50)

        XCTAssertEqual(table.indicesNear(point: [0, 0]).sorted(), [0])
        XCTAssertEqual(table.indicesNear(point: [50, 50]).sorted(), [])
        XCTAssertEqual(table.indicesNear(point: [100, 100]).sorted(), [1])

        table.update(points: [
            [0, 0], [10, 10]
        ], radius: 50)
        XCTAssertEqual(table.indicesNear(point: [0, 0]).sorted(), [0, 1])
        XCTAssertEqual(table.indicesNear(point: [50, 50]).sorted(), [])
        XCTAssertEqual(table.indicesNear(point: [100, 100]).sorted(), [])

        table.update(points: [
            [0, 0], [0, 0]
        ], radius: 50)
        XCTAssertEqual(table.indicesNear(point: [0, 0]).sorted(), [0, 1])
        XCTAssertEqual(table.indicesNear(point: [50, 50]).sorted(), [])
        XCTAssertEqual(table.indicesNear(point: [100, 100]).sorted(), [])
    }
}
