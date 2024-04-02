import Algorithms
import Foundation
import simd

// https://cs184.eecs.berkeley.edu/sp20/lecture/8-22/meshes-and-geometry-processing
public struct HalfEdgeMesh {
    public class Vertex {
        public var position: SIMD3<Float>
        public weak var halfEdge: HalfEdge?

        public init(position: SIMD3<Float>) {
            self.position = position
        }
    }

    public class Face {
        public weak var halfEdge: HalfEdge?

        public init() {
        }
    }

    public class Edge {
        public var halfEdge: HalfEdge?
    }

    public class HalfEdge {
        public var vertex: Vertex
        public var next: HalfEdge?
        public var twin: HalfEdge?
        public var face: Face?
        public var edge: Edge?

        public init(vertex: Vertex, nextEdge: HalfEdge?, twinEdge: HalfEdge?, face: Face?) {
            self.vertex = vertex
            next = nextEdge
            twin = twinEdge
            self.face = face
        }
    }

    public var faces: [Face] = []
    public var halfEdges: [HalfEdge] = []

    public init() {
    }
}

public extension HalfEdgeMesh {
    mutating func addFace(positions: [SIMD3<Float>]) {
        let face = Face()
        let vertices = positions.map { Vertex(position: $0) }
        let halfEdges = vertices.map { HalfEdge(vertex: $0, nextEdge: nil, twinEdge: nil, face: face) }
        for (first, second) in halfEdges.adjacentPairs() {
            first.next = second
            first.vertex.halfEdge = first
        }
        halfEdges.last?.next = halfEdges.first
        face.halfEdge = halfEdges.first
        faces.append(face)
        self.halfEdges.append(contentsOf: halfEdges)
    }
}
