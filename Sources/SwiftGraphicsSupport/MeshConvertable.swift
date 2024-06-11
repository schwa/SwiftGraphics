import MetalKit
import MetalSupport
import ModelIO

public protocol MDLMeshConverterProtocol: ConverterProtocol {
    var allocator: MDLMeshBufferAllocator? { get set }
    var segments: [Int] { get set }
    var inwardNormals: Bool { get set }
    var geometryType: MDLGeometryType { get set }
    var flippedTextureCoordinates: Bool { get set }

    init(allocator: MDLMeshBufferAllocator?)
}

public protocol MDLMeshConvertable {
    associatedtype MDLMeshConverter: MDLMeshConverterProtocol where MDLMeshConverter.Input == Self, MDLMeshConverter.Output == MDLMesh
}

public extension MDLMeshConvertable {
    func toMDLMesh(allocator: MDLMeshBufferAllocator?, segments: [Int]? = nil, inwardNormals: Bool = false, geometryType: MDLGeometryType = .triangles, flippedTextureCoordinates: Bool = false) throws -> MDLMesh {
        var converter = MDLMeshConverter(allocator: allocator)
        if let segments {
            converter.segments = segments
        }
        converter.inwardNormals = inwardNormals
        converter.geometryType = geometryType
        converter.flippedTextureCoordinates = flippedTextureCoordinates

        return try converter.convert(self)
    }

    func toMTKMesh(device: MTLDevice, allocator: MDLMeshBufferAllocator? = nil, segments: [Int]? = nil, inwardNormals: Bool = false, geometryType: MDLGeometryType = .triangles, flippedTextureCoordinates: Bool = false) throws -> MTKMesh {
        let allocator = allocator ?? MTKMeshBufferAllocator(device: device)
        let mdlMesh = try toMDLMesh(allocator: allocator, segments: segments, inwardNormals: inwardNormals, geometryType: geometryType, flippedTextureCoordinates: flippedTextureCoordinates)
        return try MTKMesh(mesh: mdlMesh, device: device)
    }

    func write(to url: URL) throws {
        let mdlMesh = try toMDLMesh(allocator: nil)
        let asset = MDLAsset()
        asset.add(mdlMesh)
        try asset.export(to: url)
    }
}

// MARK: -
