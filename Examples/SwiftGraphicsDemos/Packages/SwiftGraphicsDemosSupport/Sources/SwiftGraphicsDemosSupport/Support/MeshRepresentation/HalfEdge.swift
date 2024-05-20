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

// MARK: -

extension HalfEdgeMesh {
    var polygons: [Shapes3D.Polygon3D<SIMD3<Float>>] {
        faces.map(\.polygon)
    }
}

extension HalfEdgeMesh.Face {
    var polygon: Polygon3D<SIMD3<Float>> {
        .init(vertices: vertices.map(\.position))
    }
}

// MARK: -

public protocol HalfEdgeMeshConverterProtocol: ConverterProtocol {

}

public protocol HalfEdgeMeshConvertable {
    associatedtype HalfEdgeMeshConverter: HalfEdgeMeshConverterProtocol where HalfEdgeMeshConverter.Input == Self, HalfEdgeMeshConverter.Output == HalfEdgeMesh

    func toHalfEdgeMesh() throws -> HalfEdgeMesh
}

extension Box3D: HalfEdgeMeshConvertable {
    public struct HalfEdgeMeshConverter: HalfEdgeMeshConverterProtocol {
        public func convert(_ box: Box3D) throws -> HalfEdgeMesh {
            var mesh = HalfEdgeMesh()
            // Bottom face (viewed from above, must be clockwise because normally viewed from below)
            mesh.addFace(positions: [box.minXMinYMinZ, box.maxXMinYMinZ, box.maxXMaxYMinZ, box.minXMaxYMinZ])
            // Top face (viewed from above)
            mesh.addFace(positions: [box.minXMinYMaxZ, box.minXMaxYMaxZ, box.maxXMaxYMaxZ, box.maxXMinYMaxZ])
            // Left face (viewed from left)
            mesh.addFace(positions: [box.minXMinYMaxZ, box.minXMinYMinZ, box.minXMaxYMinZ, box.minXMaxYMaxZ])
            // Right face (viewed from right)
            mesh.addFace(positions: [box.maxXMinYMinZ, box.maxXMinYMaxZ, box.maxXMaxYMaxZ, box.maxXMaxYMinZ])
            // Front face (viewed from front)
            mesh.addFace(positions: [box.minXMinYMinZ, box.minXMinYMaxZ, box.maxXMinYMaxZ, box.maxXMinYMinZ])
            // Back face (viewed from back)
            mesh.addFace(positions: [box.minXMaxYMinZ, box.maxXMaxYMinZ, box.maxXMaxYMaxZ, box.minXMaxYMaxZ])
            return mesh
        }
    }

    public func toHalfEdgeMesh() throws -> HalfEdgeMesh {
        try HalfEdgeMeshConverter().convert(self)
    }
}
