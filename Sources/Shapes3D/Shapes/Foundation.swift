import simd

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

public struct LineSegment3D: Hashable {
    public var start: SIMD3<Float>
    public var end: SIMD3<Float>

    public init(start: SIMD3<Float>, end: SIMD3<Float>) {
        self.start = start
        self.end = end
    }
}

public extension LineSegment3D {
    init(_ tuple: (start: SIMD3<Float>, end: SIMD3<Float>)) {
        self.start = tuple.start
        self.end = tuple.end
    }

    func reversed() -> LineSegment3D {
        .init(start: end, end: start)
    }

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

extension LineSegment3D: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "LineSegment3D(\(start), \(end))"
    }
}

// MARK: -

public struct Plane3D {
    public var normal: SIMD3<Float>
    public var w: Float

    public init(normal: SIMD3<Float>, w: Float) {
        self.normal = normal
        self.w = w
    }
}

public extension Plane3D {
    init(points: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)) {
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

public struct PolygonalChain3D {
    public var vertices: [SIMD3<Float>]

    public init() {
        vertices = []
    }

    public init(vertices: [SIMD3<Float>]) {
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

public extension PolygonalChain3D {
    var segments: [LineSegment3D] {
        zip(vertices, vertices.dropFirst()).map { LineSegment3D(start: $0.0.position, end: $0.1.position) }
    }
}

public extension PolygonalChain3D {
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
    init(polygon: Polygon3D<SIMD3<Float>>) {
        vertices = polygon.vertices + [polygon.vertices[0]]
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
