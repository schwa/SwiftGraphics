//@testable import RenderKitScratch
//import simd
//import XCTest
//
//final class CircularPairsTests: XCTestCase {
//    func testCircularPairsEmpty() throws {
//        let array: [Int] = []
//        let result = Array(array.circularPairs())
//        XCTAssertTrue(result.isEmpty)
//    }
//
//    func testCircularPairsMultiple() throws {
//        let array = [1, 2, 3, 4]
//        let result = Array(array.circularPairs())
//        XCTAssertEqual(result.count, 4)
//        XCTAssertEqual(result.map(\.0), [1, 2, 3, 4])
//        XCTAssertEqual(result.map(\.1), [2, 3, 4, 1])
//    }
//
//    func testCircularPairsSingle() throws {
//        let array = [1]
//        let result = Array(array.circularPairs())
//        XCTAssertEqual(result.count, 1)
//        XCTAssertEqual(result.map(\.0), [1])
//        XCTAssertEqual(result.map(\.1), [1])
//    }
//}
//
//final class WingedEdgeTests: XCTestCase {
//    func testWingedEdge() throws {
//        var collection = WingedEdgeCollection()
//        collection.add(face: [
//            SIMD3<Float>(0, 0, 0),
//            SIMD3<Float>(1, 0, 0),
//            SIMD3<Float>(1, 1, 0),
//        ])
//        XCTAssertEqual(collection.faces.count, 1)
//        XCTAssertEqual(collection.vertices.count, 3)
//        XCTAssertEqual(collection.edges.count, 3)
//        XCTAssertTrue(collection.isValid)
//
//        let device = MTLCreateSystemDefaultDevice()!
//        let mesh = try collection.toMesh(device: device)
//        print(mesh)
//    }
//}
