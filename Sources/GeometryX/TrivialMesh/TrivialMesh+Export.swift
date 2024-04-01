import Foundation

// https://en.wikipedia.org/wiki/PLY_(file_format)

// Note: blender prefers "vertex_indices" and will fail with a bad header error if "vertex_index" is used.
// Note: ModelIO uses "vertex_index"

public extension TrivialMesh where Vertex == SIMD3<Float> {
    func toPLY() -> String {
        // let vertices = polygons.flatMap { $0.vertices }
        let faces: [[Int]] = indices.chunks(ofCount: 3).map { $0.map { Int($0) } }

        var s = ""
        let encoder = PlyEncoder()
        encoder.encodeHeader(to: &s)
        encoder.encodeVersion(to: &s)
        encoder.encodeElementDefinition(name: "vertex", count: vertices.count, properties: [
            (.float, "x"), (.float, "y"), (.float, "z"),
        ], to: &s)
        encoder.encodeElementDefinition(name: "face", count: faces.count, properties: [
            (.list(count: .uchar, element: .int), "vertex_indices"),
        ], to: &s)
        encoder.encodeEndHeader(to: &s)

        for vertex in vertices {
            encoder.encodeElement([
                .float(vertex.x), .float(vertex.y), .float(vertex.z),
            ], to: &s)
        }
        for face in faces {
            let indices = face.map { PlyEncoder.Value.int(Int32($0)) }
            encoder.encodeListElement(indices, to: &s)
        }

        return s
    }
}

public extension TrivialMesh where Vertex == SimpleVertex {
    func toPLY() -> String {
        // let vertices = polygons.flatMap { $0.vertices }
        let faces: [[Int]] = indices.chunks(ofCount: 3).map { $0.map { Int($0) } }

        var s = ""
        let encoder = PlyEncoder()
        encoder.encodeHeader(to: &s)
        encoder.encodeVersion(to: &s)
        encoder.encodeElementDefinition(name: "vertex", count: vertices.count, properties: [
            (.float, "x"), (.float, "y"), (.float, "z"),
            (.float, "nx"), (.float, "ny"), (.float, "nz"),
            (.float, "s"), (.float, "t"),
        ], to: &s)
        encoder.encodeElementDefinition(name: "face", count: faces.count, properties: [
            (.list(count: .uchar, element: .int), "vertex_indices"),
        ], to: &s)
        encoder.encodeEndHeader(to: &s)

        for vertex in vertices {
            encoder.encodeElement([
                .float(vertex.position.x), .float(vertex.position.y), .float(vertex.position.z),
                .float(vertex.normal.x), .float(vertex.normal.y), .float(vertex.normal.z),
                .float(vertex.textureCoordinate.x), .float(vertex.textureCoordinate.y),
            ], to: &s)
        }
        for face in faces {
            let indices = face.map { PlyEncoder.Value.int(Int32($0)) }
            encoder.encodeListElement(indices, to: &s)
        }

        return s
    }
}
