import MetalSupport
import RenderKitShaders
import Shapes3D
import SIMDSupport
import SwiftUI

protocol PolygonConvertable {
    func toPolygons() -> [Polygon3D<SimpleVertex>]
}

extension PolygonConvertable {
    func toCSG() -> CSG<SimpleVertex> {
        CSG(polygons: toPolygons())
    }
}

extension Box3D: PolygonConvertable where Vertex: PointLike3, Vertex.Scalar == Float {
    func toPolygons() -> [Polygon3D<SimpleVertex>] {
        let polygons = [
            Polygon3D(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, min.z), normal: .init(x: -1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, min.z), normal: .init(x: -1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, max.z), normal: .init(x: -1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, max.z), normal: .init(x: -1, y: 0, z: 0)),
            ]).flipped(),

            Polygon3D(vertices: [
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, min.z), normal: .init(x: 1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, max.z), normal: .init(x: 1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, max.z), normal: .init(x: 1, y: 0, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, min.z), normal: .init(x: 1, y: 0, z: 0)),
            ]).flipped(),
            Polygon3D(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, min.z), normal: .init(x: 0, y: -1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, min.z), normal: .init(x: 0, y: -1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, max.z), normal: .init(x: 0, y: -1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, max.z), normal: .init(x: 0, y: -1, z: 0)),
            ]),
            Polygon3D(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, min.z), normal: .init(x: 0, y: 1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, max.z), normal: .init(x: 0, y: 1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, max.z), normal: .init(x: 0, y: 1, z: 0)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, min.z), normal: .init(x: 0, y: 1, z: 0)),
            ]),
            Polygon3D(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, min.z), normal: .init(x: 0, y: 0, z: -1)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, min.z), normal: .init(x: 0, y: 0, z: -1)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, min.z), normal: .init(x: 0, y: 0, z: -1)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, min.z), normal: .init(x: 0, y: 0, z: -1)),
            ]),
            Polygon3D(vertices: [
                SimpleVertex(position: SIMD3<Float>(min.x, min.y, max.z), normal: .init(x: 0, y: 0, z: 1)),
                SimpleVertex(position: SIMD3<Float>(max.x, min.y, max.z), normal: .init(x: 0, y: 0, z: 1)),
                SimpleVertex(position: SIMD3<Float>(max.x, max.y, max.z), normal: .init(x: 0, y: 0, z: 1)),
                SimpleVertex(position: SIMD3<Float>(min.x, max.y, max.z), normal: .init(x: 0, y: 0, z: 1)),
            ]),
        ]
        return polygons
    }
}

extension Sphere3D: PolygonConvertable {
    func toPolygons() -> [Polygon3D<SimpleVertex>] {
        let slices = 12
        let stacks = 12
        var polygons: [Polygon3D<SimpleVertex>] = []
        func vertex(_ theta: Angle, _ phi: Angle) -> SimpleVertex {
            let dir = SIMD3<Float>(cos(Float(theta.radians)) * sin(Float(phi.radians)), cos(Float(phi.radians)), sin(Float(theta.radians)) * sin(Float(phi.radians)))
            return SimpleVertex(position: dir * radius + center, normal: dir)
        }
        for i in 0 ..< slices {
            for j in 0 ..< stacks {
                let v1 = vertex(.degrees(Double(i) / Double(slices) * 360), .degrees(Double(j) / Double(stacks) * 180))
                let v2 = vertex(.degrees(Double(i + 1) / Double(slices) * 360), .degrees(Double(j) / Double(stacks) * 180))
                let v3 = vertex(.degrees(Double(i + 1) / Double(slices) * 360), .degrees(Double(j + 1) / Double(stacks) * 180))
                let v4 = vertex(.degrees(Double(i) / Double(slices) * 360), .degrees(Double(j + 1) / Double(stacks) * 180))
                polygons.append(Polygon3D(vertices: [v1, v2, v3]))
                polygons.append(Polygon3D(vertices: [v1, v3, v4]))
            }
        }
        return polygons
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
