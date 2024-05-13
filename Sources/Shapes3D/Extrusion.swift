import Algorithms
import CoreGraphics
import Earcut
import simd
import MetalSupport
import Shapes2D

// swiftlint:disable force_unwrapping

public enum ExtrusionAxis {
    case x
    case y
    case z
}

public extension ExtrusionAxis {
    var transform: simd_float3x3 {
        switch self {
        case .x:
            simd_float3x3([0, 0, 1], [0, 1, 0], [1, 0, 0])
        case .y:
            simd_float3x3([1, 0, 0], [0, 0, 1], [0, 1, 0])
        case .z:
            simd_float3x3([1, 0, 0], [0, 1, 0], [0, 0, 1])
        }
    }
}

public extension PolygonalChain {
    func extrude(min: Float, max: Float, axis: ExtrusionAxis = .z) -> TrivialMesh<SimpleVertex> {
        let quads: [Quad<SimpleVertex>] = vertices.windows(ofCount: 2).reduce(into: []) { result, window in
            let from = SIMD2<Float>(x: Float(window.first!.x), y: Float(window.first!.y))
            let to = SIMD2<Float>(x: Float(window.last!.x), y: Float(window.last!.y))
            let transform = axis.transform

            let vertices = (
                SIMD3<Float>(from.x, from.y, min) * transform,
                SIMD3<Float>(to.x, to.y, min) * transform,
                SIMD3<Float>(from.x, from.y, max) * transform,
                SIMD3<Float>(to.x, to.y, max) * transform
            )

            let normal = simd.cross(vertices.1 - vertices.0, vertices.2 - vertices.0).normalized

            let quad = Quad(vertices: (
                SimpleVertex(position: vertices.0, normal: normal),
                SimpleVertex(position: vertices.1, normal: normal),
                SimpleVertex(position: vertices.2, normal: normal),
                SimpleVertex(position: vertices.3, normal: normal)
            ))
            result.append(quad)
        }
        let mesh = TrivialMesh<SimpleVertex>(quads: quads)
        return mesh
    }
}

extension Quad {
    func flipped() -> Self {
        Quad(vertices: (
            vertices.0, vertices.2, vertices.1, vertices.3
        ))
    }
}

public extension Polygon {
    func extrude(min: Float, max: Float, axis: ExtrusionAxis = .z, walls: Bool = true, topCap: Bool, bottomCap: Bool) -> TrivialMesh<SimpleVertex> {
        let walls = walls ? PolygonalChain(vertices: self.vertices).extrude(min: min, max: max, axis: axis) : nil
        let topCap = topCap ? triangulate(z: max, transform: axis.transform) : nil
        let bottomCap = bottomCap ? triangulate(z: min, transform: axis.transform).flipped() : nil
        return TrivialMesh(merging: Array([walls, topCap, bottomCap].compacted()))
    }

    func triangulate(z: Float = 0, transform: simd_float3x3 = .init(diagonal: [1, 1, 1])) -> TrivialMesh<SimpleVertex> {
        let indices = earcut(polygons: [vertices.map({ SIMD2($0) })]).map({ Int($0) })
        assert(!indices.isEmpty)
        let vertices = vertices.map {
            // TODO: We're not calculating texture coordinate here.
            SimpleVertex(position: [Float($0.x), Float($0.y), z] * transform, normal: [0, 0, 1] * transform, textureCoordinate: [0, 0])
        }
        return TrivialMesh(indices: indices, vertices: vertices)
    }
}

public extension SIMD2 where Scalar == Float {
    init(_ point: CGPoint) {
        self = [Float(point.x), Float(point.y)]
    }
}
