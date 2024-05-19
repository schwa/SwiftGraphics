import CoreGraphics
import ModelIO
import simd

// TODO: This file needs a big makeover. See also MeshConvertable.

public struct Cylinder3D {
    public var radius: Float
    public var depth: Float

    public init(radius: Float, depth: Float) {
        self.radius = radius
        self.depth = depth
    }
}

// MARK: -

// MARK: -

// MARK: -

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

// MARK: -

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

// MARK: -

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

// MARK: -

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

// TODO: Will deprecate
// @available(*, deprecated, message: "Break into shape3d and a meshconvertable")
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

// TODO: Will deprecate
// @available(*, deprecated, message: "Break into shape3d and a meshconvertable")
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
