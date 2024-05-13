import Algorithms
import MetalSupport
import simd

// TODO: Rename to "TriangleMesh"
public struct TrivialMesh<Vertex> where Vertex: Equatable {
    public var label: String?
    public var indices: [Int]
    public var vertices: [Vertex]

    public init(label: String? = nil, indices: [Int], vertices: [Vertex]) {
        self.label = label
        self.indices = indices
        self.vertices = vertices
    }

    public init(label: String? = nil) {
        self.init(label: label, indices: [], vertices: [])
    }
}

// MARK: -

public extension TrivialMesh {
    init(merging meshes: [TrivialMesh]) {
        self = meshes.reduce(into: TrivialMesh()) { result, mesh in
            let offset = result.vertices.count
            result.indices.append(contentsOf: mesh.indices.map { $0 + Int(offset) })
            result.vertices.append(contentsOf: mesh.vertices)
            // TODO: Does not compact vertices
        }
    }

    mutating func append(vertex: Vertex, optimizing: Bool = true) {
        if optimizing, let index = vertices.firstIndex(of: vertex) {
            indices.append(index)
        }
        else {
            indices.append(vertices.count)
            vertices.append(vertex)
        }
    }

    func reversed() -> TrivialMesh {
        let indices = indices.chunks(ofCount: 3).flatMap {
            $0.reversed()
        }
        return TrivialMesh(indices: indices, vertices: vertices)
    }

    func transformedVertices(_ transform: (Vertex) -> Vertex) -> Self {
        TrivialMesh(indices: indices, vertices: vertices.map { transform($0) })
    }
}

// MARK: -

public extension TrivialMesh where Vertex: VertexLike {
    init(quads: [Quad<Vertex>], optimizing: Bool = true) {
        let triangles = quads.flatMap { let triangles = $0.subdivide(); return [triangles.0, triangles.1] }
        self.init(triangles: triangles, optimizing: optimizing)
    }

    init(triangles: [Triangle3D<Vertex>], optimizing: Bool = true) {
        self.init()
        for triangle in triangles {
            append(vertex: triangle.vertices.0, optimizing: optimizing)
            append(vertex: triangle.vertices.1, optimizing: optimizing)
            append(vertex: triangle.vertices.2, optimizing: optimizing)
        }
    }
}

// MARK: -

public extension TrivialMesh where Vertex == SIMD3<Float> {
    // TODO: We can replace this with an extension.
    var boundingBox: Box3D<SIMD3<Float>> {
        guard let first = vertices.first else {
            return Box3D(min: .zero, max: .zero)
        }
        let min = vertices.dropFirst().reduce(into: first) { result, vertex in
            result.x = Swift.min(result.x, vertex.x)
            result.y = Swift.min(result.y, vertex.y)
            result.z = Swift.min(result.z, vertex.z)
        }
        let max = vertices.dropFirst().reduce(into: first) { result, vertex in
            result.x = Swift.max(result.x, vertex.x)
            result.y = Swift.max(result.y, vertex.y)
            result.z = Swift.max(result.z, vertex.z)
        }
        return Box3D(min: min, max: max)
    }

    func flipped() -> Self {
        let indices = indices.chunks(ofCount: 3).flatMap { $0.reversed() }
        return TrivialMesh(indices: indices, vertices: vertices)
    }

    func offset(by delta: SIMD3<Float>) -> TrivialMesh {
        TrivialMesh(indices: indices, vertices: vertices.map { $0 + delta })
    }

    func scale(by scale: SIMD3<Float>) -> TrivialMesh {
        TrivialMesh(indices: indices, vertices: vertices.map { $0 * scale })
    }
}

public extension TrivialMesh where Vertex == SimpleVertex {
    var boundingBox: Box3D<SIMD3<Float>> {
        guard let first = vertices.first?.position else {
            return Box3D(min: .zero, max: .zero)
        }
        let min = vertices.dropFirst().reduce(into: first) { result, vertex in
            result.x = Swift.min(result.x, vertex.position.x)
            result.y = Swift.min(result.y, vertex.position.y)
            result.z = Swift.min(result.z, vertex.position.z)
        }
        let max = vertices.dropFirst().reduce(into: first) { result, vertex in
            result.x = Swift.max(result.x, vertex.position.x)
            result.y = Swift.max(result.y, vertex.position.y)
            result.z = Swift.max(result.z, vertex.position.z)
        }
        return Box3D(min: min, max: max)
    }

    func flipped() -> Self {
        let indices = indices.chunks(ofCount: 3).flatMap { $0.reversed() }
        let vertices = vertices.map {
            var vertex = $0
            vertex.normal *= -1
            return vertex
        }
        return TrivialMesh(indices: indices, vertices: vertices)
    }

    func offset(by delta: SIMD3<Float>) -> TrivialMesh {
        TrivialMesh(indices: indices, vertices: vertices.map {
            SimpleVertex(position: $0.position + delta, normal: $0.normal, textureCoordinate: $0.textureCoordinate)
        })
    }

    func scale(by scale: SIMD3<Float>) -> TrivialMesh {
        TrivialMesh(indices: indices, vertices: vertices.map {
            SimpleVertex(position: $0.position * scale, normal: $0.normal, textureCoordinate: $0.textureCoordinate)
        })
    }

    var isValid: Bool {
        // Not a mesh of triangles...
        if indices.count % 3 != 0 {
            return false
        }

        // Index points to a missing vertex
        if indices.contains(where: { Int($0) > vertices.count }) {
            return false
        }

        // Bad vertices
        if vertices.contains(where: {
            $0.position.x.isNaN || $0.position.y.isNaN || $0.position.y.isNaN
                || $0.position.x.isInfinite || $0.position.y.isInfinite || $0.position.y.isInfinite
                || $0.normal.x.isNaN || $0.normal.y.isNaN || $0.normal.y.isNaN
                || $0.normal.x.isInfinite || $0.normal.y.isInfinite || $0.normal.y.isInfinite
        }) {
            return false
        }

        // Make sure all normals are unit vectors.
        if vertices.contains(where: {
            let error = abs(1.0 - simd_length_squared($0.normal))
            return error > 0.000001
        }) {
            return false
        }

        return true
    }

    var triangles: [Triangle3D<SimpleVertex>] {
        indices.chunks(ofCount: 3).map { indices in
            let indices = indices.map { Int($0) }
            let p0 = vertices[indices[0]]
            let p1 = vertices[indices[1]]
            let p2 = vertices[indices[2]]
            return Triangle3D(vertices: (p0, p1, p2))
        }
    }

    func renormalize(averaging: Bool = true) -> Self {
        // Step 1. Regenerate mesh from mesh's triangles to make sure no vertices are re-used.
        let mesh = TrivialMesh(triangles: triangles, optimizing: false)

        // Step 2. Generate triangle normals.
        var vertices = mesh.indices.chunks(ofCount: 3).reduce(into: mesh.vertices) { vertices, indices in
            let indices = indices.map { Int($0) }
            let p0 = vertices[indices[0]].position
            let p1 = vertices[indices[1]].position
            let p2 = vertices[indices[2]].position
            let normal = simd.cross(p1 - p0, p2 - p0).normalized
            vertices[indices[0]].normal = normal
            vertices[indices[1]].normal = normal
            vertices[indices[2]].normal = normal
        }

        // Step 3. Optionally average normals.
        if averaging {
            // Find all vertex indexes that share a position
            let indicesByPosition: [SIMD3<Float>: [Int]] = vertices.indices.reduce(into: [:]) { partialResult, index in
                let vertex = vertices[index]
                partialResult[vertex.position, default: []].append(index)
            }
            // Now assign average normals to all vertices with shared positions
            for indices in indicesByPosition.values {
                let normals = indices.map { vertices[$0].normal }
                let average = normals.reduce(.zero, +) / Float(normals.count)
                for index in indices {
                    vertices[index].normal = average
                }
            }
        }

        return .init(indices: mesh.indices, vertices: vertices)
    }
}
