import MetalKit
import MetalSupport
import ModelIO

public protocol MDLMeshConverterProtocol: ConverterProtocol {
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

public extension MDLMeshConvertable {
    func toMDLMesh(allocator: MDLMeshBufferAllocator?) throws -> MDLMesh {
        let converter = MDLMeshConverter(allocator: allocator)
        return try converter.convert(self)
    }

    func toMTKMesh(allocator: MDLMeshBufferAllocator? = nil, device: MTLDevice) throws -> MTKMesh {
        let allocator = allocator ?? MTKMeshBufferAllocator(device: device)
        let mdlMesh = try toMDLMesh(allocator: allocator)
        return try MTKMesh(mesh: mdlMesh, device: device)
    }
}
