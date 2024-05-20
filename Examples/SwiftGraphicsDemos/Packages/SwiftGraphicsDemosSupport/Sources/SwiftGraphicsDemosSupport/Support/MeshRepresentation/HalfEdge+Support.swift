import Algorithms
import Foundation
import simd
import Shapes3D
import os

extension HalfEdgeMesh where Position == SIMD3<Float> {
    var polygons: [Shapes3D.Polygon3D<SIMD3<Float>>] {
        faces.map(\.polygon)
    }
}

extension HalfEdgeMesh.Face where Position == SIMD3<Float> {
    var polygon: Polygon3D<SIMD3<Float>> {
        .init(vertices: vertices.map(\.position))
    }
}

// MARK: -

public protocol HalfEdgeMeshConverterProtocol: ConverterProtocol {

}

public protocol HalfEdgeMeshConvertable {
    associatedtype HalfEdgeMeshConverter: HalfEdgeMeshConverterProtocol where HalfEdgeMeshConverter.Input == Self, HalfEdgeMeshConverter.Output == HalfEdgeMesh<SIMD3<Float>>

    func toHalfEdgeMesh() throws -> HalfEdgeMesh<SIMD3<Float>>
}

extension Box3D: HalfEdgeMeshConvertable {
    public struct HalfEdgeMeshConverter: HalfEdgeMeshConverterProtocol {
        public func convert(_ box: Box3D) throws -> HalfEdgeMesh<SIMD3<Float>> {
            var mesh = HalfEdgeMesh<SIMD3<Float>>(polygons: [
                // Bottom face (viewed from above, must be clockwise because normally viewed from below)
                .init(vertices: [box.minXMinYMinZ, box.maxXMinYMinZ, box.maxXMaxYMinZ, box.minXMaxYMinZ]),
                // Top face (viewed from above)
                .init(vertices: [box.minXMinYMaxZ, box.minXMaxYMaxZ, box.maxXMaxYMaxZ, box.maxXMinYMaxZ]),
                // Left face (viewed from left)
                .init(vertices: [box.minXMinYMaxZ, box.minXMinYMinZ, box.minXMaxYMinZ, box.minXMaxYMaxZ]),
                // Right face (viewed from right)
                .init(vertices: [box.maxXMinYMinZ, box.maxXMinYMaxZ, box.maxXMaxYMaxZ, box.maxXMaxYMinZ]),
                // Front face (viewed from front)
                .init(vertices: [box.minXMinYMinZ, box.minXMinYMaxZ, box.maxXMinYMaxZ, box.maxXMinYMinZ]),
                // Back face (viewed from back)
                .init(vertices: [box.minXMaxYMinZ, box.maxXMaxYMinZ, box.maxXMaxYMaxZ, box.minXMaxYMaxZ]),
            ])
            return mesh
        }
    }

    public func toHalfEdgeMesh() throws -> HalfEdgeMesh<SIMD3<Float>> {
        try HalfEdgeMeshConverter().convert(self)
    }
}

extension HalfEdgeMesh {
    func isValid(logger: Logger? = .init()) -> Bool {
        let allFaces = Set(faces.map(\.id))
        guard allFaces.count == faces.count else {
            logger?.error("Faces do not all have a unique id.")
            return false
        }
        let allHalfEdges = Set(halfEdges.map(\.id))
        guard allHalfEdges.count == halfEdges.count else {
            logger?.error("Half-edges do not all have a unique id.")
            return false
        }
        for face in faces {
            guard let faceHalfEdge = face.halfEdge else {
                logger?.error("Face missing a half-edge.")
                return false
            }
            guard allHalfEdges.contains(faceHalfEdge.id) else {
                logger?.error("Face's half edge not in mesh's half-edges.")
                return false
            }

            // TODO: get rid of !
            guard face.halfEdges.last!.next!.id == face.halfEdge!.id else {
                logger?.error("Face's last half-edge's next is not face's first half-edge.")
                return false
            }
        }

        let faceHalfEdges = faces.flatMap { $0.halfEdges }
        guard Set(faceHalfEdges.map(\.id)) == allHalfEdges else {
            logger?.error("Mesh half-edges do not match mesh face half-edges.")
            return false
        }

        for halfEdge in halfEdges {
            if let twin = halfEdge.twin {
                guard let twinTwin = twin.twin, twinTwin.id == halfEdge.id else {
                    logger?.error("A half-edge's twin's twin isn't this the half-edge.")
                    return false
                }
            }
        }


        return true
    }
}
