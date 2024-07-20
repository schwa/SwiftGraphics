import BaseSupport
import CoreGraphics
import MetalSupport
import ModelIO
import simd

public protocol Face {
    mutating func flip()
}

public extension Face {
    func flipped() -> Self {
        var copy = self
        copy.flip()
        return copy
    }
}

// MARK: -

public struct Polygon3D<Vertex: VertexLike> {
    public var vertices: [Vertex]

    public init(vertices: [Vertex]) {
        self.vertices = vertices
    }
}

extension Polygon3D: Face where Vertex: VertexLike3 {
    public mutating func flip() {
        vertices = vertices.reversed().map { vertex in
            var vertex = vertex
            vertex.normal = -vertex.normal
            return vertex
        }
    }
}

public extension Polygon3D where Vertex: VertexLike3, Vertex.Vector == SIMD3<Float> {
    var plane: Plane3D {
        Plane3D(points: (vertices[0].position, vertices[1].position, vertices[2].position))
    }
}

public extension Polygon3D where Vertex == SIMD3<Float> {
    init(polygonalChain: PolygonalChain3D) {
        self.init(vertices: polygonalChain.isClosed ? polygonalChain.vertices.dropLast() : polygonalChain.vertices)
    }

    var segments: [LineSegment3D] {
        vertices.circularPairs().map(LineSegment3D.init)
    }
}

// MARK: -

public struct Quad<Vertex: VertexLike> {
    public var vertices: (Vertex, Vertex, Vertex, Vertex)

    public init(vertices: (Vertex, Vertex, Vertex, Vertex)) {
        self.vertices = vertices
    }
}

public extension Quad where Vertex == SIMD3<Float> {
    init(x: Float, y: Float, width: Float, height: Float) {
        self.vertices = (
            [x, y, 0],
            [x, y + height, 0],
            [x + width, y + height, 0],
            [x + width, y, 0]
        )
    }
}

public extension Quad where Vertex == SimpleVertex {
    init(x: Float, y: Float, width: Float, height: Float) {
        let normal: SIMD3<Float> = [0, 0, 1]
        self.vertices = (
            .init(position: [x, y, 0], normal: normal, textureCoordinate: [0, 0]),
            .init(position: [x, y + height, 0], normal: normal, textureCoordinate: [0, 1]),
            .init(position: [x + width, y + height, 0], normal: normal, textureCoordinate: [1, 1]),
            .init(position: [x + width, y, 0], normal: normal, textureCoordinate: [1, 0])
        )
    }
}

public extension Quad {
    init(vertices: [Vertex]) {
        assert(vertices.count == 4)
        self.vertices = (vertices[0], vertices[1], vertices[2], vertices[3])
    }
}

public extension Quad {
    func subdivide() -> (Triangle3D<Vertex>, Triangle3D<Vertex>) {
        // 1---2        0---3
        // |\  |        |  /|
        // | \ |        | / |
        // |  \|        |/  |
        // 0---3        1---2
        (
            Triangle3D(vertices: (vertices.0, vertices.1, vertices.3)),
            Triangle3D(vertices: (vertices.1, vertices.2, vertices.3))
        )
    }
}

// MARK: -

public struct Triangle3D<Vertex: VertexLike> {
    public var vertices: (Vertex, Vertex, Vertex)

    public init(vertices: (Vertex, Vertex, Vertex)) {
        self.vertices = vertices
    }
}
