import CoreGraphics
import CoreGraphicsSupport
import Testing

@Test
func testCGSizeOperators() {
    #expect(CGSize(width: 10, height: 100) * 10 == CGSize(width: 100, height: 1000))
}
