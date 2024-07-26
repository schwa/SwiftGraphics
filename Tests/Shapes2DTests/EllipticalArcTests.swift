@testable import Shapes2D
import Testing

@Test func ellipticalArcTests() {
    let arc = EllipticalArc(center: .zero, a: 10, b: 20, theta: 30)
    let path = arc.buildPathIterator(degree: 10, threshold: 0.1)
    #expect(path.isEmpty == false)
}
