import Algorithms
import Foundation
import simd
import Shapes3D
import SwiftGraphicsSupport

// TODO: Replace pointers with indices
// TODO: Face 0 of every half mesh indicates the "outside" face. So every half edge always has a twin.
// TODO: Reduce optional pointers/indices (face always has at least 3 half edges, a half edge always has a face)
// TODO: Edges - they're kind of synthetic
// TODO: Make it so that indices can be any size (generic). Means we need an AnyHalfEdgeMesh (gross). Indices are going to make deletion shittier though.
// TODO: Make it so we can add generic data to edges, faces, vertices
// TODO: Makt it so position is generic.

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
        weak var halfEdge: HalfEdge? //

        init() {
        }
    }

    public class HalfEdge: Identifiable {
        var vertex: Vertex
        var next: HalfEdge?
        var twin: HalfEdge?
        var face: Face?

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

    init(polygons: [Polygon3D<SIMD3<Float>>]) {
        self.init()
        self.addFaces(polygons)
    }

    mutating func addFaces(_ polygons: [Polygon3D<SIMD3<Float>>]) {
        var halfEdgesBySegment: [LineSegment3D: HalfEdge] = [:]

        for polygon in polygons {
            let face = Face()
            let segments = polygon.segments
            let halfEdges = segments.map { HalfEdge(vertex: Vertex(position: $0.end), nextEdge: nil, twinEdge: nil, face: face) }
            for (segment, halfEdge) in zip(segments, halfEdges) {
                assert(halfEdgesBySegment[segment] == nil)
                halfEdgesBySegment[segment] = halfEdge
            }
            for (first, second) in halfEdges.adjacentPairs() {
                first.next = second
                first.vertex.halfEdge = first
            }
            halfEdges.last?.next = halfEdges.first
            face.halfEdge = halfEdges.first
            faces.append(face)
            self.halfEdges.append(contentsOf: halfEdges)
        }

        for (segment, halfEdge) in halfEdgesBySegment {
            let reverseSegment = segment.reversed()
            if let twinEdge = halfEdgesBySegment[reverseSegment] {
                halfEdge.twin = twinEdge
                twinEdge.twin = halfEdge
            }
        }
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
