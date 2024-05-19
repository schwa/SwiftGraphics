import MetalKit
import MetalSupport
import ModelIO
import SIMDSupport
import SwiftUI

@available(*, deprecated, message: "Deprecated.")
public protocol Shape3D: Hashable, Sendable {
    func toMDLMesh(allocator: MDLMeshBufferAllocator?) -> MDLMesh
}

@available(*, deprecated, message: "Deprecated.")
public extension Shape3D {
    func toMTKMesh(allocator: MDLMeshBufferAllocator?, device: MTLDevice) throws -> MTKMesh {
        let mdlMesh = toMDLMesh(allocator: allocator)
        return try MTKMesh(mesh: mdlMesh, device: device)
    }
}
