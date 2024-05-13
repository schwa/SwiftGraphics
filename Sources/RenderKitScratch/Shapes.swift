//import simd
//import RenderKitShaders
//import RenderKit
//
//public struct Line3D {
//    public var point: SIMD3<Float>
//    public var direction: SIMD3<Float>
//
//    public init(point: SIMD3<Float>, direction: SIMD3<Float>) {
//        assert(direction != .zero)
//        self.point = point
//        self.direction = direction
//    }
//}
//
//// MARK: -
//
//public struct Ray3D {
//    public var origin: SIMD3<Float>
//    public var direction: SIMD3<Float>
//
//    public init(origin: SIMD3<Float>, direction: SIMD3<Float>) {
//        self.origin = origin
//        self.direction = direction
//    }
//}
//
//// MARK: -
//
//public struct LineSegment3D {
//    public var start: SIMD3<Float>
//    public var end: SIMD3<Float>
//
//    public init(start: SIMD3<Float>, end: SIMD3<Float>) {
//        self.start = start
//        self.end = end
//    }
//}
//
//public extension LineSegment3D {
//    var direction: SIMD3<Float> {
//        end - start
//    }
//
//    var length: Float {
//        simd.length(direction)
//    }
//
//    var lengthSquared: Float {
//        simd.length_squared(direction)
//    }
//
//    var normalizedDirection: SIMD3<Float> {
//        direction / length
//    }
//
//    func point(at t: Float) -> SIMD3<Float> {
//        start + t * direction
//    }
//}
//
//// MARK: -
//
//public extension Line3D {
//    init(_ segment: LineSegment3D) {
//        self.init(point: segment.start, direction: segment.direction)
//    }
//}
//
//// MARK: -
//
//public struct PolygonalChain3D {
//    public var vertices: [SIMD3<Float>]
//}
//
//public extension PolygonalChain3D {
//    var isClosed: Bool {
//        vertices.first == vertices.last
//    }
//
//    var segments: [LineSegment3D] {
//        zip(vertices, vertices.dropFirst()).map(LineSegment3D.init)
//    }
//
//    var isSelfIntersecting: Bool {
//        fatalError()
//    }
//
//    var isCoplanar: Bool {
//        if vertices.count <= 3 {
//            return true
//        }
//        let normal = simd.cross(segments[0].direction, segments[1].direction)
//        for segment in segments.dropFirst(2) {
//            if simd.dot(segment.direction, normal) != 0 {
//                return false
//            }
//        }
//        return true
//    }
//}
//
//public struct Sphere {
//    public var center: SIMD3<Float>
//    public var radius: Float
//
//    public init(center: SIMD3<Float>, radius: Float) {
//        self.center = center
//        self.radius = radius
//    }
//}
//
//public struct Box {
//    public var min: SIMD3<Float>
//    public var max: SIMD3<Float>
//
//    public init(min: SIMD3<Float>, max: SIMD3<Float>) {
//        self.min = min
//        self.max = max
//    }
//}
//
//public struct Triangle3D {
//    public var vertices: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)
//
//    public init(vertices: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)) {
//        self.vertices = vertices
//    }
//}
//
//public protocol VertexLike: Hashable, Sendable {
//    var position: SIMD3<Float> { get set }
//    var normal: SIMD3<Float> { get set }
//
//    init()
//}
//
//extension SimpleVertex: VertexLike {
//}
//
//extension VertexLike {
//    func interpolate(_ other: Self, _ value: Float) -> Self {
//        var result = Self()
//        result.position = simd_mix(position, other.position, .init(repeating: value))
//        result.normal = simd_mix(normal, other.normal, .init(repeating: value))
//        return result
//    }
//}
//
//public struct Polygon3D<Vertex> where Vertex: VertexLike {
//    public var vertices: [Vertex]
//
//    public init(vertices: [Vertex]) {
//        self.vertices = vertices
//    }
//}
//
//extension Polygon3D: Hashable {
//}
//
//public extension Polygon3D {
//    mutating func flip() {
//        vertices = vertices.reversed().map { vertex in
//            var vertex = vertex
//            vertex.normal = -vertex.normal
//            return vertex
//        }
//    }
//
//    func flipped() -> Self {
//        var copy = self
//        copy.flip()
//        return copy
//    }
//}
//
//public struct Plane {
//    public var normal: SIMD3<Float>
//    public var w: Float
//
//    public init(normal: SIMD3<Float>, w: Float) {
//        self.normal = normal
//        self.w = w
//    }
//}
//
//public extension Plane {
//    init(points: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)) {
//        let (a, b, c) = points
//        let n = simd.cross(b - a, c - a).normalized
//        self.init(normal: n, w: simd.dot(n, a))
//    }
//}
//
//public extension Plane {
//    mutating func flip() {
//        normal = -normal
//        w = -w
//    }
//
//    func flipped() -> Plane {
//        var plane = self
//        plane.flip()
//        return plane
//    }
//}
//
//extension Polygon3D {
//    var plane: Plane {
//        Plane(points: (vertices[0].position, vertices[1].position, vertices[2].position))
//    }
//}
