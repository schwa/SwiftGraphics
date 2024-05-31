import Foundation
import MetalKit
import MetalSupport
import SwiftFormats
import SwiftGLTF
import SwiftGraphicsSupport
import SwiftUI

extension SwiftGLTF.Accessor {
    var vertexFormat: MTLVertexFormat? {
        switch (componentType, type) {
        case (.FLOAT, .SCALAR):
            .float
        case (.FLOAT, .VEC2):
            .float2
        case (.FLOAT, .VEC3):
            .float3
        case (.FLOAT, .VEC4):
            .float4
        default:
            unimplemented() // MORE TO DO
        }
    }

    var indexType: MTLIndexType {
        switch (componentType, type) {
        case (.UNSIGNED_SHORT, .SCALAR), (.SHORT, .SCALAR):
            .uint16
        case (.UNSIGNED_INT, .SCALAR):
            .uint32
        default:
            unreachable()
        }
    }
}

extension MTLDevice {
    func makeBuffer(data: Data, options: MTLResourceOptions) -> MTLBuffer? {
        data.withUnsafeBytes { buffer in
            makeBuffer(bytes: buffer.baseAddress!, length: buffer.count, options: options)
        }
    }
}

extension YAMesh {
    init(gltf name: String, in bundle: Bundle = .main, device: MTLDevice) throws {
        let url = bundle.url(forResource: name, withExtension: "glb")!
        let container = try Container(url: url)
//        dump(container)
        let node = try container.document.scenes[0].nodes[0].resolve(in: container.document)
        let mesh = try node.mesh!.resolve(in: container.document)
        assert(mesh.primitives.count == 1)
        let primitive = mesh.primitives.first!
        try self.init(container: container, primitive: primitive, device: device)
    }

    init(container: SwiftGLTF.Container, primitive: SwiftGLTF.Mesh.Primitive, device: MTLDevice) throws {
        func makeBuffer(for bufferView: SwiftGLTF.BufferView, label: String) -> MTLBuffer {
            let data = try! container.data(for: bufferView)
            let buffer = device.makeBuffer(data: data, options: [])!
            buffer.label = label
            return buffer
        }

        var bufferViews: [SwiftGraphicsSupport.BufferView] = []

        let semantics: [(SwiftGLTF.Mesh.Primitive.Semantic, VertexDescriptor.Attribute.Semantic, Int)] = [
            (.POSITION, .position, 10),
            (.NORMAL, .normal, 11),
            (.TEXCOORD_0, .textureCoordinate, 12),
        ]

        var descriptor = VertexDescriptor()
        for (gltfSemantic, semantic, index) in semantics {
            guard let accessor = try primitive.attributes[gltfSemantic]?.resolve(in: container.document) else {
                continue
            }
            assert(accessor.byteOffset == 0)
            let bufferView = try accessor.bufferView!.resolve(in: container.document)
            assert(bufferView.byteStride == nil)
            let mtlBuffer = makeBuffer(for: bufferView, label: "\(container.url.lastPathComponent):\(semantic):\(index)")

            bufferViews.append(BufferView(buffer: mtlBuffer, offset: 0))

            descriptor.layouts.append(.init(label: nil, bufferIndex: index, stride: 0, stepFunction: .perVertex, stepRate: 1, attributes: [
                .init(semantic: semantic, format: accessor.vertexFormat!, offset: 0),
            ]))
        }
        descriptor.setPackedOffsets()
        descriptor.setPackedStrides()

        let accessor = try primitive.indices!.resolve(in: container.document)
        let bufferView = try accessor.bufferView!.resolve(in: container.document)
        assert(bufferView.byteStride == nil)
        let mtlBuffer: MTLBuffer! = makeBuffer(for: bufferView, label: "\(container.url.lastPathComponent):indices")
        let indexBufferView = BufferView(label: "Indices", buffer: mtlBuffer, offset: 0)
        let indexType: MTLIndexType = accessor.indexType
        let indexCount = accessor.count
        guard let primitiveType = MTLPrimitiveType(primitive.mode) else {
            fatalError("Unknown primitive type")
        }
        self = YAMesh(label: container.url.lastPathComponent, indexType: indexType, indexBufferView: indexBufferView, indexCount: indexCount, vertexDescriptor: descriptor, vertexBufferViews: bufferViews, primitiveType: primitiveType)
    }
}

extension MTLPrimitiveType {
    init?(_ mode: SwiftGLTF.Mesh.Primitive.Mode) {
        switch mode {
        case .POINTS:
            self = .point
        case .LINES:
            self = .line
        case .LINE_LOOP:
            return nil
        case .LINE_STRIP:
            self = .lineStrip
        case .TRIANGLES:
            self = .triangle
        case .TRIANGLE_STRIP:
            self = .triangleStrip
        case .TRIANGLE_FAN:
            return nil
        }
    }
}

extension MTLStepFunction: CustomStringConvertible {
    public var description: String {
        switch self {
        case .perVertex:
            "perVertex"
        case .perInstance:
            "perInstance"
        default:
            unimplemented()
        }
    }
}
