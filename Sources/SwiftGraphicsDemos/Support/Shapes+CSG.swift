import MetalSupport
import RenderKitShaders
import Shapes3D
import SwiftUI

extension PolygonConvertable {
    func toCSG() throws -> CSG<SimpleVertex> {
        CSG(polygons: try toPolygons())
    }
}

extension Triangle3D {
    func toCSG() -> CSG<SimpleVertex> where Vertex == SIMD3<Float> {
        let v1 = SimpleVertex(position: vertices.0, normal: .zero)
        let v2 = SimpleVertex(position: vertices.1, normal: .zero)
        let v3 = SimpleVertex(position: vertices.2, normal: .zero)
        return CSG(polygons: [Polygon3D(vertices: [v1, v2, v3])])
    }
}

extension CSG where Vertex == SimpleVertex {
    func toPLY() -> String {
        let vertices = polygons.flatMap(\.vertices)
        let faces: [[Int]] = polygons.reduce(into: []) { partialResult, polygon in
            let nextIndex = partialResult.map(\.count).reduce(0, +)
            partialResult.append(Array(nextIndex ..< nextIndex + polygon.vertices.count))
        }
        var s = ""
        let encoder = PlyEncoder()
        encoder.encodeHeader(to: &s)
        encoder.encodeVersion(to: &s)
        encoder.encodeElementDefinition(name: "vertex", count: vertices.count, properties: [
            (.float, "x"), (.float, "y"), (.float, "z"),
            (.float, "nx"), (.float, "ny"), (.float, "nz"),
            (.uchar, "red"), (.uchar, "green"), (.uchar, "blue"),
        ], to: &s)
        encoder.encodeElementDefinition(name: "face", count: faces.count, properties: [
            (.list(count: .uchar, element: .int), "vertex_indices"),
        ], to: &s)
        encoder.encodeEndHeader(to: &s)

        for vertex in vertices {
            encoder.encodeElement([
                .float(vertex.position.x), .float(vertex.position.y), .float(vertex.position.z),
                .float(vertex.normal.x), .float(vertex.normal.y), .float(vertex.normal.z),
                .uchar(128), .uchar(128), .uchar(128),
            ], to: &s)
        }
        for face in faces {
            let indices = face.map { PlyEncoder.Value.int(Int32($0)) }
            encoder.encodeListElement(indices, to: &s)
        }

        return s
    }
}

extension CGRect {
    func toCSG() -> CSG<SimpleVertex> {
        let vertices = [minXMinY, maxXMinY, maxXMaxY, minXMaxY]
            .map {
                SimpleVertex(position: SIMD3(SIMD2($0), 0), normal: [0, 0, 1])
            }
        return CSG(polygons: [Polygon3D(vertices: vertices)])
    }
}
