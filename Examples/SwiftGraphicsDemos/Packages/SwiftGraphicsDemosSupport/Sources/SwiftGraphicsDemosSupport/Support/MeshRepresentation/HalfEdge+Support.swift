import Algorithms
import Foundation
import simd
import Shapes3D

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
