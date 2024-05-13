import ModelIO
import MetalKit

public protocol MeshConvertable {
    associatedtype Input
    associatedtype Output

    func toMesh(_ value: Input) throws -> Output
}

@available(*, deprecated, message: "Removed")
public protocol Shape3D: Hashable, Sendable {
    func toMDLMesh(allocator: MDLMeshBufferAllocator?) -> MDLMesh
}

public extension Shape3D {
    
    @available(*, deprecated, message: "Removed")
    func toMTKMesh(allocator: MDLMeshBufferAllocator?, device: MTLDevice) throws -> MTKMesh {
        let mdlMesh = toMDLMesh(allocator: allocator)
        return try MTKMesh(mesh: mdlMesh, device: device)
    }
}
