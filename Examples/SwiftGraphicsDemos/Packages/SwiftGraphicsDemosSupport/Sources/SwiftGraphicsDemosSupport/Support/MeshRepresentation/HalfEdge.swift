import Algorithms
import Foundation
import simd

// https://cs184.eecs.berkeley.edu/sp20/lecture/8-22/meshes-and-geometry-processing
struct HalfEdgeMesh {
    class Vertex {
        var position: SIMD3<Float>
        weak var halfEdge: HalfEdge?

        init(position: SIMD3<Float>) {
            self.position = position
        }
    }

    class Face {
        weak var halfEdge: HalfEdge?

        init() {
        }
    }

    class Edge {
        var halfEdge: HalfEdge?
    }

    class HalfEdge {
        var vertex: Vertex
        var next: HalfEdge?
        var twin: HalfEdge?
        var face: Face?
        var edge: Edge?

        init(vertex: Vertex, nextEdge: HalfEdge?, twinEdge: HalfEdge?, face: Face?) {
            self.vertex = vertex
            next = nextEdge
            twin = twinEdge
            self.face = face
        }
    }

    var faces: [Face] = []
    var halfEdges: [HalfEdge] = []
}

extension HalfEdgeMesh {
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
