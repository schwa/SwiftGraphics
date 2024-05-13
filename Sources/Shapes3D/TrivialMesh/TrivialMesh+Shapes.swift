import Foundation
import simd
import MetalSupport

public extension TrivialMesh where Vertex == SimpleVertex {
    @available(*, deprecated, message: "Move to MeshConvertable")
    init(cylinder: Cylinder3D, segments: Int) {
        let halfDepth = cylinder.depth / 2
        let circle = TrivialMesh(circleRadius: cylinder.radius, segments: segments)
        let top = circle.offset(by: [0, 0, halfDepth])
        let bottom = circle.flipped().offset(by: [0, 0, -halfDepth])

        func makeEdge() -> Self {
            let segmentAngle = Float.pi * 2 / Float(segments)
            let quads = (0 ..< segments).map { index in
                let startAngle = segmentAngle * Float(index)
                let endAngle = segmentAngle * Float(index + 1)
                let p1 = SIMD3(cos(startAngle) * cylinder.radius, sin(startAngle) * cylinder.radius, 0)
                let p2 = SIMD3(cos(endAngle) * cylinder.radius, sin(endAngle) * cylinder.radius, 0)
                let vertices = [
                    p1 + [0, 0, -halfDepth],
                    p2 + [0, 0, -halfDepth],
                    p1 + [0, 0, halfDepth],
                    p2 + [0, 0, halfDepth],
                ]
                .map {
                    SimpleVertex(position: $0, normal: simd_normalize($0), textureCoordinate: [0, 0])
                }
                return Quad(vertices: vertices)
            }
            return .init(quads: quads)
        }
        self = TrivialMesh(merging: [top, bottom, makeEdge()])
        assert(isValid)
    }

    @available(*, deprecated, message: "Move to MeshConvertable")
    init(circleRadius radius: Float, segments: Int) {
        let segmentAngle = Float.pi * 2 / Float(segments)
        let vertices2D = [
            SIMD2<Float>(0, 0),
        ] + (0 ..< (segments)).map {
            SIMD2<Float>(cos(segmentAngle * Float($0)), sin(segmentAngle * Float($0))) * radius
        }
        let vertices = vertices2D.map {
            SimpleVertex(position: SIMD3<Float>($0.x, $0.y, 0), normal: [0, 0, 1], textureCoordinate: $0)
        }
        let indices: [Int] = (0 ..< segments).flatMap {
            let p1 = 1 + $0
            let p2 = 1 + ($0 + 1) % segments
            return [0, p1, p2]
        }
        self = .init(indices: indices, vertices: vertices)
        assert(isValid)
//        try! self.write(to: URL(filePath: "/tmp/test.obj"))
    }
}
