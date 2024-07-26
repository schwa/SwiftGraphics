import GenericGeometryBase
import Testing

@Test
func test() {
    let r = IntRect(minX: 0, minY: 0, maxX: 10, maxY: 10)
    #expect(r == IntRect(0, 0, 10, 10))
}
