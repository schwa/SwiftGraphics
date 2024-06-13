import Testing

import SwiftGraphicsDemosSupport

@Test func testSimplePly() throws {
    let source = """
        ply
        format ascii 1.0
        element vertex 2
        property float x
        end_header
        12345 54321
        """
    let ply = try Ply(source: source)
    #expect(ply.elements[0].records[0].values[0].float == 12345)
    #expect(ply.elements[0].records[1].values[0].float == 54321)
}
