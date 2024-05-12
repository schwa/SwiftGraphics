import XCTest
@testable import RenderKit

final class VertexDescriptorTests: XCTestCase {
    func testVertexDescriptor() throws {
        let d = VertexDescriptor.packed(semantics: [.position, .normal, .textureCoordinate])
        XCTAssertEqual(d.layouts[0].attributes[0], .init(semantic: .position, format: .float3, offset: 0))
        XCTAssertEqual(d.layouts[0].attributes[1], .init(semantic: .normal, format: .float3, offset: 12))
        XCTAssertEqual(d.layouts[0].attributes[2], .init(semantic: .textureCoordinate, format: .float2, offset: 24))
        XCTAssertEqual(d.layouts[0].stepFunction, .perVertex)
        XCTAssertEqual(d.layouts[0].stepRate, 1)
        XCTAssertEqual(d.layouts[0].stride, 32)

        let mtl = MTLVertexDescriptor(d)
        XCTAssertEqual(mtl.attributes[0].format, .float3)
        XCTAssertEqual(mtl.attributes[0].offset, 0)
        XCTAssertEqual(mtl.attributes[0].bufferIndex, 0)
        XCTAssertEqual(mtl.attributes[1].format, .float3)
        XCTAssertEqual(mtl.attributes[1].offset, 12)
        XCTAssertEqual(mtl.attributes[1].bufferIndex, 0)
        XCTAssertEqual(mtl.attributes[2].format, .float2)
        XCTAssertEqual(mtl.attributes[2].offset, 24)
        XCTAssertEqual(mtl.attributes[2].bufferIndex, 0)
        XCTAssertEqual(mtl.layouts[0].stepFunction, .perVertex)
        XCTAssertEqual(mtl.layouts[0].stepRate, 1)
        XCTAssertEqual(mtl.layouts[0].stride, 32)

        var d2 = try VertexDescriptor(mtl)
        XCTAssertNil(d2.layouts[0].attributes[0].semantic)
        XCTAssertNil(d2.layouts[0].attributes[1].semantic)
        XCTAssertNil(d2.layouts[0].attributes[2].semantic)
        d2.layouts[0].attributes[0].semantic = .position
        d2.layouts[0].attributes[1].semantic = .normal
        d2.layouts[0].attributes[2].semantic = .textureCoordinate
        XCTAssertEqual(d, d2)

/*
 <MTLVertexDescriptorInternal: 0x6000037d9140>
     Buffer 0:
         stepFunction = MTLVertexStepFunctionPerVertex
         stride = 32
         Attribute 0:
             offset = 0
             format = MTLAttributeFormatFloat3
         Attribute 1:
             offset = 12
             format = MTLAttributeFormatFloat3
         Attribute 2:
             offset = 24
             format = MTLAttributeFormatFloat2
*/
    }
}
