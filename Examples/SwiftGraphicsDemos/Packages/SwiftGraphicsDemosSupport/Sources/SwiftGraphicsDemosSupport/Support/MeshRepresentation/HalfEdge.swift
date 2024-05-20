import Algorithms
import Foundation
import simd
import Shapes3D

// https://cs184.eecs.berkeley.edu/sp20/lecture/8-22/meshes-and-geometry-processing
public struct HalfEdgeMesh {
    public class Vertex: Identifiable {
        var position: SIMD3<Float>
        weak var halfEdge: HalfEdge?

        init(position: SIMD3<Float>) {
            self.position = position
        }
    }

    public class Face: Identifiable {
        weak var halfEdge: HalfEdge?

        init() {
        }
    }

    public class Edge: Identifiable {
        var halfEdge: HalfEdge?

        var twin: HalfEdge? {
            return halfEdge?.twin
        }

        init() {
        }
    }

    public class HalfEdge: Identifiable {
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
        // TODO: Twin is not being added.
        // TODO: Edge is not being added
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

extension HalfEdgeMesh.Face {
    var halfEdges: [HalfEdgeMesh.HalfEdge] {
        var edges: [HalfEdgeMesh.HalfEdge] = []
        var current: HalfEdgeMesh.HalfEdge! = halfEdge
        repeat {
            edges.append(current)
            current = current.next
        }
        while current !== halfEdge
        return edges
    }

    var vertices: [HalfEdgeMesh.Vertex] {
        halfEdges.map(\.vertex)
    }
}
