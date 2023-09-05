import CoreImage
@testable import Everything
import Foundation
import XCTest

class CoreGraphicsTests: XCTestCase {
    func test1() {
        let pixels = Array2D<SIMD4<UInt8>>(flatStorage: [
            [255, 0, 0, 255],
            [0, 255, 0, 255],
            [0, 0, 255, 255],
            [0, 0, 0, 255],
        ], size: [2, 2])
            .flipped(axis: .horizontal)
        let image = pixels.cgImage
        XCTAssertEqual(Array2D<SIMD4<UInt8>>(cgImage: image.subimage(at: [0, 0, 1, 1]))[0, 0], [255, 0, 0, 255])
        XCTAssertEqual(Array2D<SIMD4<UInt8>>(cgImage: image.subimage(at: [1, 0, 1, 1]))[0, 0], [0, 255, 0, 255])
        XCTAssertEqual(Array2D<SIMD4<UInt8>>(cgImage: image.subimage(at: [0, 1, 1, 1]))[0, 0], [0, 0, 255, 255])
        XCTAssertEqual(Array2D<SIMD4<UInt8>>(cgImage: image.subimage(at: [1, 1, 1, 1]))[0, 0], [0, 0, 0, 255])
    }
}
