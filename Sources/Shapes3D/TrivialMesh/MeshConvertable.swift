import MetalKit
import MetalSupport
import ModelIO

// TODO: will deprecate
// @available(*, deprecated, message: "Removed")
public protocol Shape3D: Hashable, Sendable {
    func toMDLMesh(allocator: MDLMeshBufferAllocator?) -> MDLMesh
}

public extension Shape3D {
    func toMTKMesh(allocator: MDLMeshBufferAllocator?, device: MTLDevice) throws -> MTKMesh {
        let mdlMesh = toMDLMesh(allocator: allocator)
        return try MTKMesh(mesh: mdlMesh, device: device)
    }
}

public protocol MeshConverterProtocol {
    associatedtype Input
    associatedtype Output

    func toMesh(_ value: Input) throws -> Output
}

public protocol MDLMeshConverterProtocol: MeshConverterProtocol {
    var segments: [Int] { get set }
    var inwardNormals: Bool { get set }
    var geometryType: MDLGeometryType { get set }
    var flippedTextureCoordinates: Bool { get set }
    var allocator: MDLMeshBufferAllocator? { get set }

    init(allocator: MDLMeshBufferAllocator?)
}

public protocol MDLMeshConvertable {
    associatedtype MDLMeshConverter: MDLMeshConverterProtocol where MDLMeshConverter.Input == Self, MDLMeshConverter.Output == MDLMesh
}

extension Sphere3D: MDLMeshConvertable {
    public struct MDLMeshConverter: MDLMeshConverterProtocol {
        public var segments: [Int]
        public var inwardNormals: Bool
        public var geometryType: MDLGeometryType
        public var flippedTextureCoordinates: Bool
        public var allocator: MDLMeshBufferAllocator?

        public init(allocator: MDLMeshBufferAllocator?) {
            segments = [36, 36]
            inwardNormals = false
            geometryType = .triangles
            flippedTextureCoordinates = false
            self.allocator = allocator
        }

        public init(segments: [Int] = [36, 36], inwardNormals: Bool = false, geometryType: MDLGeometryType = .triangles, flippedTextureCoordinates: Bool = false, allocator: MDLMeshBufferAllocator) {
            self.segments = segments
            self.inwardNormals = inwardNormals
            self.geometryType = geometryType
            self.flippedTextureCoordinates = flippedTextureCoordinates
            self.allocator = allocator
        }

        public func toMesh(_ sphere: Sphere3D) throws -> MDLMesh {
            assert(segments.count == 2)
            let mesh = MDLMesh(sphereWithExtent: [sphere.radius * 2, sphere.radius * 2, sphere.radius * 2], segments: SIMD2<UInt32>(segments.map { UInt32($0) }), inwardNormals: inwardNormals, geometryType: .triangles, allocator: allocator)
            if flippedTextureCoordinates {
                mesh.flipTextureCoordinates(inAttributeNamed: "textureCoordinate")
            }
            return mesh
        }
    }
}

public extension MDLMeshConvertable {
    func toMDLMesh(allocator: MDLMeshBufferAllocator?) throws -> MDLMesh {
        let converter = MDLMeshConverter(allocator: allocator)
        return try converter.toMesh(self)
    }

    func toMTKMesh(allocator: MDLMeshBufferAllocator?, device: MTLDevice) throws -> MTKMesh {
        let mdlMesh = try toMDLMesh(allocator: allocator)
        return try MTKMesh(mesh: mdlMesh, device: device)
    }
}
