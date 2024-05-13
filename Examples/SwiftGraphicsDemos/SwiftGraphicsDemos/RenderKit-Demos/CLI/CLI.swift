import Foundation
import Metal
import MetalKit
import ModelIO
import RenderKit

@main
struct Main {
    static func main() async throws {
//        try await OffscreenDemo.main()

        let device = MTLCreateSystemDefaultDevice()!

        let mesh = try Sphere().toYAMesh(allocator: MTKMeshBufferAllocator(device: device), device: device)
        print(mesh)
    }
}

extension YAMesh {
    func toMDLMesh() throws -> MDLMesh {
        let vertexBuffers = vertexBufferViews.map { bufferView in
            MDLMeshBufferData(type: .vertex, data: Data(bufferView))
        }
        let vertexDescriptor = MDLVertexDescriptor(vertexDescriptor)
        let submeshes = submeshes.map { submesh in
            let indexBuffer = MDLMeshBufferData(type: .index, data: Data(submesh.indexBufferView))
            return MDLSubmesh(indexBuffer: indexBuffer, indexCount: 0, indexType: .invalid, geometryType: .lines, material: nil)
        }
        return MDLMesh(vertexBuffers: vertexBuffers, vertexCount: 0, descriptor: vertexDescriptor, submeshes: submeshes)
    }
}

extension YAMesh {
    func write(to url: URL) throws {
        let mdlMesh = try toMDLMesh()
        let asset = MDLAsset()
        asset.add(mdlMesh)
        try asset.export(to: url)
    }
}

extension Data {
    init(_ buffer: BufferView) {
        fatalError()
    }
}

extension MDLVertexDescriptor {
    convenience init(_ vertexDescriptor: VertexDescriptor) {
        fatalError()
    }
}
