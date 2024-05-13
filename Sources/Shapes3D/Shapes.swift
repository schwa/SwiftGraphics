import CoreGraphics
import simd
import ModelIO

// TODO: This file needs a big makeover. See also MeshConvertable.

// MARK: Platonic Solids

// Tetrahedron
// Cube
// Octahedron
// Dodecahedron
// Icosahedron

// MARK: -

// Sphere
// Hemisphere
// Box
// Pyramid
// // Truncated Cone
// Hemioctahedron

// Cone
// Truncated Cone
// Capsule
// Torus
// Prism

// MARK: -

public struct Box3D<Vertex: VertexLike> {
    public var min: Vertex
    public var max: Vertex

    public init(min: Vertex, max: Vertex) {
        self.min = min
        self.max = max
    }
}

// MARK: -

public struct Cylinder3D {
    public var radius: Float
    public var depth: Float

    public init(radius: Float, depth: Float) {
        self.radius = radius
        self.depth = depth
    }
}

// MARK: -

public struct Line3D {
    public var point: SIMD3<Float>
    public var direction: SIMD3<Float>

    public init(point: SIMD3<Float>, direction: SIMD3<Float>) {
        assert(direction != .zero)
        self.point = point
        self.direction = direction
    }
}

public extension Line3D {
    init(_ segment: LineSegment3D) {
        self.init(point: segment.start, direction: segment.direction)
    }
}

// MARK: -

public struct LineSegment3D {
    public var start: SIMD3<Float>
    public var end: SIMD3<Float>

    public init(start: SIMD3<Float>, end: SIMD3<Float>) {
        self.start = start
        self.end = end
    }
}

public extension LineSegment3D {
    var direction: SIMD3<Float> {
        (end - start).normalized
    }

    var length: Float {
        direction.length
    }

    var lengthSquared: Float {
        direction.lengthSquared
    }

    var normalizedDirection: SIMD3<Float> {
        direction / length
    }

    func point(at t: Float) -> SIMD3<Float> {
        start + direction * t
    }
}

// MARK: -

// TODO: Make generic so we can have floats & points
public struct Plane3D<Scalar> where Scalar: SIMDScalar & FloatingPoint {
    public var normal: SIMD3<Scalar>
    public var w: Scalar

    public init(normal: SIMD3<Scalar>, w: Scalar) {
        self.normal = normal
        self.w = w
    }
}

public extension Plane3D where Scalar == Float {
    init(points: (SIMD3<Scalar>, SIMD3<Scalar>, SIMD3<Scalar>)) {
        let (a, b, c) = points
        let n = simd.cross(b - a, c - a).normalized
        self.init(normal: n, w: simd.dot(n, a))
    }
}

public extension Plane3D {
    mutating func flip() {
        normal = -normal
        w = -w
    }

    func flipped() -> Plane3D {
        var plane = self
        plane.flip()
        return plane
    }
}

// MARK: -

public struct Polygon3D<Vertex: VertexLike> {
    public var vertices: [Vertex]

    public init(vertices: [Vertex]) {
        self.vertices = vertices
    }
}

public extension Polygon3D where Vertex: VertexLike3 {
    mutating func flip() {
        vertices = vertices.reversed().map { vertex in
            var vertex = vertex
            vertex.normal = -vertex.normal
            return vertex
        }
    }

    func flipped() -> Self {
        var copy = self
        copy.flip()
        return copy
    }
}

public extension Polygon3D where Vertex: VertexLike3, Vertex.Vector == SIMD3<Float> {
    var plane: Plane3D<Float> {
        Plane3D(points: (vertices[0].position, vertices[1].position, vertices[2].position))
    }
}

//public extension Polygon3D {
//    var plane: Plane3D<Float> {
//        Plane3D(points: (vertices[0], vertices[1], vertices[2]))
//    }
//}

public extension Polygon3D {
    init(polygonalChain: PolygonalChain3D<Vertex>) {
        self.init(vertices: polygonalChain.isClosed ? polygonalChain.vertices.dropLast() : polygonalChain.vertices)
    }
}

// MARK: -

public struct PolygonalChain3D<Vertex: VertexLike> {
    public var vertices: [Vertex]

    public init() {
        vertices = []
    }

    public init(vertices: [Vertex]) {
        self.vertices = vertices
    }
}

public extension PolygonalChain3D {
    var isClosed: Bool {
        vertices.first == vertices.last
    }

    var isSelfIntersecting: Bool {
        fatalError()
    }
}


public extension PolygonalChain3D where Vertex.Vector == SIMD3<Float> {
    var segments: [LineSegment3D] {
        zip(vertices, vertices.dropFirst()).map { LineSegment3D(start: $0.0.position, end: $0.1.position)}
    }

}

public extension PolygonalChain3D where Vertex == SIMD3<Float> {
    var isCoplanar: Bool {
        if vertices.count <= 3 {
            return true
        }
        let normal = simd.cross(segments[0].direction, segments[1].direction)
        for segment in segments.dropFirst(2) {
            if simd.dot(segment.direction, normal) != 0 {
                return false
            }
        }
        return true
    }
}

public extension PolygonalChain3D {
    init(polygon: Polygon3D<Vertex>) {
        vertices = polygon.vertices + [polygon.vertices[0]]
    }
}

// MARK: -

public struct Quad<Vertex: VertexLike> {
    public var vertices: (Vertex, Vertex, Vertex, Vertex)

    public init(vertices: (Vertex, Vertex, Vertex, Vertex)) {
        self.vertices = vertices
    }
}

public extension Quad {
    init(vertices: [Vertex]) {
        assert(vertices.count == 4)
        self.vertices = (vertices[0], vertices[1], vertices[2], vertices[3])
    }
}

public extension Quad {
    func subdivide() -> (Triangle3D<Vertex>, Triangle3D<Vertex>) {
        // 1---3
        // |\  |
        // | \ |
        // |  \|
        // 0---2
        (
            Triangle3D(vertices: (vertices.0, vertices.1, vertices.2)),
            Triangle3D(vertices: (vertices.1, vertices.3, vertices.2))
        )
    }
}

// MARK: -

public struct Ray3D {
    public var origin: SIMD3<Float>
    public var direction: SIMD3<Float>

    public init(origin: SIMD3<Float>, direction: SIMD3<Float>) {
        self.origin = origin
        self.direction = direction
    }
}

// MARK: -

public struct Sphere3D {
    public var center: SIMD3<Float>
    public var radius: Float

    public init(center: SIMD3<Float> = .zero, radius: Float = 0.5) {
        self.center = center
        self.radius = radius
    }
}

// MARK: -

public struct Triangle3D<Vertex: VertexLike> {
    public var vertices: (Vertex, Vertex, Vertex)

    public init(vertices: (Vertex, Vertex, Vertex)) {
        self.vertices = vertices
    }
}

public extension Triangle3D {
    var reversed: Triangle3D {
        .init(vertices: (vertices.2, vertices.1, vertices.0))
    }
}

// MARK: -

@available(*, deprecated, message: "Break into shape3d and a meshconvertable")
public struct CubeX: Shape3D {
    public var extent: SIMD3<Float>
    public var segments: SIMD3<UInt32>
    public var inwardNormals: Bool
    public var geometryType: MDLGeometryType
    public var flippedTextureCoordinates: Bool

    public init(extent: SIMD3<Float> = [1, 1, 1], segments: SIMD3<UInt32> = [1, 1, 1], inwardNormals: Bool = false, geometryType: MDLGeometryType = .triangles, flippedTextureCoordinates: Bool = true) {
        self.extent = extent
        self.segments = segments
        self.inwardNormals = inwardNormals
        self.geometryType = geometryType
        self.flippedTextureCoordinates = flippedTextureCoordinates
    }

    public func toMDLMesh(allocator: MDLMeshBufferAllocator?) -> MDLMesh {
        let mesh = MDLMesh(boxWithExtent: extent, segments: segments, inwardNormals: inwardNormals, geometryType: geometryType, allocator: allocator)
        if flippedTextureCoordinates {
            mesh.flipTextureCoordinates(inAttributeNamed: "textureCoordinate")
        }
        return mesh
    }
}
//

@available(*, deprecated, message: "Break into shape3d and a meshconvertable")
public struct PlaneX: Shape3D {
    public var extent: SIMD3<Float>
    public var segments: SIMD2<UInt32>
    public var geometryType: MDLGeometryType
    public var flippedTextureCoordinates: Bool

    public init(extent: SIMD3<Float>, segments: SIMD2<UInt32> = [1, 1], geometryType: MDLGeometryType = .triangles, flippedTextureCoordinates: Bool = true) {
        self.extent = extent
        self.segments = segments
        self.geometryType = geometryType
        self.flippedTextureCoordinates = flippedTextureCoordinates
    }

    public func toMDLMesh(allocator: MDLMeshBufferAllocator?) -> MDLMesh {
        let mesh = MDLMesh(planeWithExtent: extent, segments: segments, geometryType: geometryType, allocator: allocator)
        if flippedTextureCoordinates {
            mesh.flipTextureCoordinates(inAttributeNamed: "textureCoordinate")
        }
        return mesh
    }
}

@available(*, deprecated, message: "Break into shape3d and a meshconvertable")
public struct CircleX: Shape3D {
    public var extent: SIMD3<Float>
    public var segments: Float
    public var geometryType: MDLGeometryType
    public var flippedTextureCoordinates: Bool

    public init(extent: SIMD3<Float>, segments: Float = 36, geometryType: MDLGeometryType = .triangles, flippedTextureCoordinates: Bool = true) {
        self.extent = extent
        self.segments = segments
        self.geometryType = geometryType
        self.flippedTextureCoordinates = flippedTextureCoordinates
    }

    public func toMDLMesh(allocator: MDLMeshBufferAllocator?) -> MDLMesh {
        fatalError()
    }
}

@available(*, deprecated, message: "Break into shape3d and a meshconvertable")
public struct Sphere3DX: Shape3D {
    public var extent: SIMD3<Float>
    public var segments: SIMD2<UInt32>
    public var inwardNormals: Bool
    public var geometryType: MDLGeometryType
    public var flippedTextureCoordinates: Bool

    public init(extent: SIMD3<Float> = [1, 1, 1], segments: SIMD2<UInt32> = [36, 36], inwardNormals: Bool = false, geometryType: MDLGeometryType = .triangles, flippedTextureCoordinates: Bool = false) {
        self.extent = extent
        self.segments = segments
        self.inwardNormals = inwardNormals
        self.geometryType = geometryType
        self.flippedTextureCoordinates = flippedTextureCoordinates
    }

    public func toMDLMesh(allocator: MDLMeshBufferAllocator?) -> MDLMesh {
        let mesh = MDLMesh(sphereWithExtent: extent, segments: segments, inwardNormals: inwardNormals, geometryType: .triangles, allocator: allocator)
        if flippedTextureCoordinates {
            mesh.flipTextureCoordinates(inAttributeNamed: "textureCoordinate")
        }
        return mesh
    }
}


@available(*, deprecated, message: "Break into shape3d and a meshconvertable")
public struct Cone3D: Shape3D {
    public var extent: SIMD3<Float>
    public var segments: SIMD2<UInt32>
    public var inwardNormals: Bool
    public var cap: Bool
    public var geometryType: MDLGeometryType
    public var flippedTextureCoordinates: Bool

    public init(extent: SIMD3<Float> = [1, 1, 1], segments: SIMD2<UInt32> = [36, 36], inwardNormals: Bool = false, cap: Bool = true, geometryType: MDLGeometryType = .triangles, flippedTextureCoordinates: Bool = true) {
        self.extent = extent
        self.segments = segments
        self.inwardNormals = inwardNormals
        self.cap = cap
        self.geometryType = geometryType
        self.flippedTextureCoordinates = flippedTextureCoordinates
    }

    public func toMDLMesh(allocator: MDLMeshBufferAllocator?) -> MDLMesh {
        let mesh = MDLMesh(coneWithExtent: extent, segments: segments, inwardNormals: inwardNormals, cap: cap, geometryType: .triangles, allocator: allocator)
        if flippedTextureCoordinates {
            mesh.flipTextureCoordinates(inAttributeNamed: "textureCoordinate")
        }
        return mesh
    }
}

@available(*, deprecated, message: "Break into shape3d and a meshconvertable")
public struct Capsule3D: Shape3D {
    public var extent: SIMD3<Float>
    public var cylinderSegments: SIMD2<UInt32>
    public var hemisphereSegments: Int32
    public var inwardNormals: Bool
    public var cap: Bool
    public var geometryType: MDLGeometryType
    public var flippedTextureCoordinates: Bool

    public init(extent: SIMD3<Float> = [1, 1, 1], cylinderSegments: SIMD2<UInt32> = [36, 36], hemisphereSegments: Int32 = 18, inwardNormals: Bool = false, cap: Bool = true, geometryType: MDLGeometryType = .triangles, flippedTextureCoordinates: Bool = true) {
        self.extent = extent
        self.cylinderSegments = cylinderSegments
        self.hemisphereSegments = hemisphereSegments
        self.inwardNormals = inwardNormals
        self.cap = cap
        self.geometryType = geometryType
        self.flippedTextureCoordinates = flippedTextureCoordinates
    }

    public func toMDLMesh(allocator: MDLMeshBufferAllocator?) -> MDLMesh {
        let mesh = MDLMesh(capsuleWithExtent: extent, cylinderSegments: cylinderSegments, hemisphereSegments: hemisphereSegments, inwardNormals: inwardNormals, geometryType: .triangles, allocator: allocator)
        if flippedTextureCoordinates {
            mesh.flipTextureCoordinates(inAttributeNamed: "textureCoordinate")
        }
        return mesh
    }
}
