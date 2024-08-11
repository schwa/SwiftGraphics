import Foundation
import MetalSupport
import simd

public extension TrivialMesh where Vertex == SimpleVertex {
    static func generatePlane(extent: SIMD2<Float>, segments: SIMD2<Int>) -> Self {
        let vertices = (0 ... segments.y).flatMap { y in
            (0 ... segments.x).map { x in
                let position = SIMD2(Float(x) / Float(segments.x), Float(y) / Float(segments.y))
                return SimpleVertex(position: SIMD3(position * extent, 0), normal: [0, 0, 1], textureCoordinate: position)
            }
        }

        func xyToIndex(x: Int, y: Int) -> Int {
            y * (segments.x * 2) + x
        }

        // 2------1  5
        // |     /  /|
        // |    /  / |
        // |   /  /  |
        // |  /  /   |
        // | /  /    |
        // |/  /     |
        // 0  3------4
        let indices = (0 ..< segments.y).flatMap { y in
            (0 ..< segments.x).flatMap { x in
                [
                    xyToIndex(x: x, y: y), xyToIndex(x: x + 1, y: y + 1), xyToIndex(x: x, y: y + 1),
                    xyToIndex(x: x, y: y), xyToIndex(x: x + 1, y: y), xyToIndex(x: x + 1, y: y + 1)
                ]
            }
        }

        return .init(indices: indices, vertices: vertices)
    }
}
