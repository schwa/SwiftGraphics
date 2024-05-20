import CoreGraphics
import ModelIO
import simd
import SwiftGraphicsSupport

public protocol Face {
    associatedtype Vertex: VertexLike

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

public extension Quad {
    init(vertices: [Vertex]) {
        assert(vertices.count == 4)
        self.vertices = (vertices[0], vertices[1], vertices[2], vertices[3])
    }
}

public extension Quad {
    func subdivide() -> (Triangle3D<Vertex>, Triangle3D<Vertex>) {
        // 1---3
        // |\  |
        // | \ |
        // |  \|
        // 0---2
        (
            Triangle3D(vertices: (vertices.0, vertices.1, vertices.2)),
            Triangle3D(vertices: (vertices.1, vertices.3, vertices.2))
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
