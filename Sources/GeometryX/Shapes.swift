import CoreGraphics
import simd

public struct Box<Point: PointLike> {
    public var min: Point
    public var max: Point

    public init(min: Point, max: Point) {
        self.min = min
        self.max = max
    }
}

// MARK: -

public struct Cylinder {
    public var radius: Float
    public var depth: Float

    public init(radius: Float, depth: Float) {
        self.radius = radius
        self.depth = depth
    }
}

// MARK: -

public struct Line<Point: PointLike> {
    public var point: Point
    public var direction: Point // TODO: Vector not Point.

    public init(point: Point, direction: Point) {
        assert(direction != .zero)
        self.point = point
        self.direction = direction
    }
}

public extension Line {
    init(_ segment: LineSegment<Point>) {
        self.init(point: segment.start, direction: segment.direction)
    }
}

// MARK: -

public struct LineSegment<Point: PointLike> {
    public var start: Point
    public var end: Point

    public init(start: Point, end: Point) {
        self.start = start
        self.end = end
    }
}

public extension LineSegment {
    var direction: Point {
        (end - start).normalized
    }

    var length: Point.Scalar {
        direction.length
    }

    var lengthSquared: Point.Scalar {
        direction.lengthSquared
    }

    var normalizedDirection: Point {
        direction / length
    }

    func point(at t: Point.Scalar) -> Point {
        start + direction * t
    }
}

// MARK: -

// TODO: Make generic so we can have floats & points
public struct Plane<Scalar> where Scalar: SIMDScalar & FloatingPoint {
    public var normal: SIMD3<Scalar>
    public var w: Scalar

    public init(normal: SIMD3<Scalar>, w: Scalar) {
        self.normal = normal
        self.w = w
    }
}

public extension Plane where Scalar == Float {
    init(points: (SIMD3<Scalar>, SIMD3<Scalar>, SIMD3<Scalar>)) {
        let (a, b, c) = points
        let n = simd.cross(b - a, c - a).normalized
        self.init(normal: n, w: simd.dot(n, a))
    }
}

public extension Plane {
    mutating func flip() {
        normal = -normal
        w = -w
    }

    func flipped() -> Plane {
        var plane = self
        plane.flip()
        return plane
    }
}

// MARK: -

public struct Polygon<Vertex> {
    public var vertices: [Vertex]

    public init(vertices: [Vertex]) {
        self.vertices = vertices
    }
}

public extension Polygon where Vertex: VertexLike3 {
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

public extension Polygon where Vertex: VertexLike3, Vertex.Vector == SIMD3<Float> {
    var plane: Plane<Float> {
        Plane(points: (vertices[0].position, vertices[1].position, vertices[2].position))
    }
}

public extension Polygon where Vertex == SIMD3<Float> {
    var plane: Plane<Float> {
        Plane(points: (vertices[0], vertices[1], vertices[2]))
    }
}

public extension Polygon where Vertex: PointLike {
    init(polygonalChain: PolygonalChain<Vertex>) {
        self.init(vertices: polygonalChain.isClosed ? polygonalChain.vertices.dropLast() : polygonalChain.vertices)
    }
}

// MARK: -

public struct PolygonalChain<Point> {
    public var vertices: [Point]

    public init() {
        vertices = []
    }

    public init(vertices: [Point]) {
        self.vertices = vertices
    }
}

public extension PolygonalChain where Point: PointLike {
    var isClosed: Bool {
        vertices.first == vertices.last
    }

    var segments: [LineSegment<Point>] {
        zip(vertices, vertices.dropFirst()).map(LineSegment.init)
    }

    var isSelfIntersecting: Bool {
        fatalError()
    }
}

public extension PolygonalChain where Point == SIMD3<Float> {
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

public extension PolygonalChain {
    init(polygon: Polygon<Point>) {
        vertices = polygon.vertices + [polygon.vertices[0]]
    }
}

// MARK: -

public struct Quad<Point: VertexLike> {
    public var vertices: (Point, Point, Point, Point)

    public init(vertices: (Point, Point, Point, Point)) {
        self.vertices = vertices
    }
}

public extension Quad {
    init(vertices: [Point]) {
        assert(vertices.count == 4)
        self.vertices = (vertices[0], vertices[1], vertices[2], vertices[3])
    }
}

public extension Quad {
    func subdivide() -> (Triangle<Point>, Triangle<Point>) {
        // 1---3
        // |\  |
        // | \ |
        // |  \|
        // 0---2
        (
            Triangle(vertices: (vertices.0, vertices.1, vertices.2)),
            Triangle(vertices: (vertices.1, vertices.3, vertices.2))
        )
    }
}

// MARK: -

public struct Ray {
    public var origin: SIMD3<Float>
    public var direction: SIMD3<Float>

    public init(origin: SIMD3<Float>, direction: SIMD3<Float>) {
        self.origin = origin
        self.direction = direction
    }
}

// MARK: -

public struct Sphere {
    public var center: SIMD3<Float>
    public var radius: Float

    public init(center: SIMD3<Float>, radius: Float) {
        self.center = center
        self.radius = radius
    }
}

// MARK: -

public struct Triangle<Point: VertexLike> {
    public var vertices: (Point, Point, Point)

    public init(vertices: (Point, Point, Point)) {
        self.vertices = vertices
    }
}

public extension Triangle {
    var reversed: Triangle {
        .init(vertices: (vertices.2, vertices.1, vertices.0))
    }
}
