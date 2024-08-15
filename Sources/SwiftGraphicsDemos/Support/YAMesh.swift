import BaseSupport
@preconcurrency import Metal
import MetalKit
import MetalSupport
import ModelIO
// typealias SemanticSet = Set<Semantic> // TODO: Use BitSet<UIntX>
//
// enum BufferRole: Hashable, Sendable {
//    case indices
//    case vertices(SemanticSet)
//    case other
// }

// MARK: -

struct BufferView: Labeled, Sendable {
    var label: String?
    var buffer: MTLBuffer
    var offset: Int

    init(label: String? = nil, buffer: MTLBuffer, offset: Int) {
        self.label = label
        self.buffer = buffer
        self.offset = offset
    }
}

extension BufferView: CustomStringConvertible {
    var description: String {
        "BufferView(label: \"\(label ?? "")\", buffer: \(buffer.gpuAddress, format: .hex), offset: \(offset))"
    }
}

// MARK: -

// TODO: Deprecate?
struct YAMesh: Identifiable, Labeled, Sendable {
    var id = TrivialID(for: Self.self)
    var label: String?
    var submeshes: [Submesh]
    var vertexDescriptor: VertexDescriptor
    var vertexBufferViews: [BufferView]

    init(label: String? = nil, submeshes: [Submesh], vertexDescriptor: VertexDescriptor, vertexBufferViews: [BufferView]) {
        self.label = label
        self.submeshes = submeshes
        self.vertexDescriptor = vertexDescriptor
        self.vertexBufferViews = vertexBufferViews
    }

    struct Submesh: Labeled, Sendable {
        var label: String?
        var indexType: MTLIndexType
        var indexBufferView: BufferView
        var indexCount: Int
        var primitiveType: MTLPrimitiveType

        init(label: String? = nil, indexType: MTLIndexType, indexBufferView: BufferView, indexCount: Int, primitiveType: MTLPrimitiveType) {
            self.label = label
            self.indexType = indexType
            self.indexBufferView = indexBufferView
            self.indexCount = indexCount
            self.primitiveType = primitiveType
        }
    }
}

// MARK: -

extension YAMesh {
    init(label: String? = nil, indexType: MTLIndexType, indexBufferView: BufferView, indexCount: Int, vertexDescriptor: VertexDescriptor, vertexBufferViews: [BufferView], primitiveType: MTLPrimitiveType) {
        let submesh = Submesh(indexType: indexType, indexBufferView: indexBufferView, indexCount: indexCount, primitiveType: primitiveType)
        self = .init(label: label, submeshes: [submesh], vertexDescriptor: vertexDescriptor, vertexBufferViews: vertexBufferViews)
    }

    init(label: String? = nil, indexType: MTLIndexType, indexBufferView: BufferView, indexCount: Int, vertexDescriptor: VertexDescriptor, vertexBuffer: MTLBuffer, vertexBufferOffset: Int, primitiveType: MTLPrimitiveType) {
        assert(vertexDescriptor.layouts.count == 1)
        self = .init(label: label, indexType: indexType, indexBufferView: indexBufferView, indexCount: indexCount, vertexDescriptor: vertexDescriptor, vertexBufferViews: [BufferView(buffer: vertexBuffer, offset: vertexBufferOffset)], primitiveType: primitiveType)
    }
}

extension YAMesh {
    // TODO: Maybe deprecate? @available(*, deprecated, message: "Deprecated")
    static func simpleMesh(label: String? = nil, indices: [UInt16], vertices: [SimpleVertex], primitiveType: MTLPrimitiveType = .triangle, device: MTLDevice) throws -> YAMesh {
        let indexBuffer = try device.makeBuffer(bytesOf: indices, options: .storageModeShared)
        indexBuffer.label = "\(label ?? "unlabeled YAMesh"):indices"
        let indexBufferView = BufferView(buffer: indexBuffer, offset: 0)
        let vertexBuffer = try device.makeBuffer(bytesOf: vertices, options: .storageModeShared)
        vertexBuffer.label = "\(label ?? "unlabeled YAMesh"):vertices"
        assert(vertexBuffer.length == vertices.count * 32)
        let vertexBufferView = BufferView(buffer: vertexBuffer, offset: 0)
        let vertexDescriptor = VertexDescriptor.packed(semantics: [.position, .normal, .textureCoordinate])
        return YAMesh(indexType: .uint16, indexBufferView: indexBufferView, indexCount: indices.count, vertexDescriptor: vertexDescriptor, vertexBufferViews: [vertexBufferView], primitiveType: primitiveType)
    }
}

extension MTLRenderCommandEncoder {
    func setVertexBuffers(_ mesh: YAMesh) {
        for (layout, bufferView) in zip(mesh.vertexDescriptor.layouts, mesh.vertexBufferViews) {
            setVertexBuffer(bufferView.buffer, offset: bufferView.offset, index: layout.bufferIndex)
        }
    }

    func draw(_ mesh: YAMesh) {
        for submesh in mesh.submeshes {
            drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBufferView.buffer, indexBufferOffset: submesh.indexBufferView.offset)
        }
    }

    func draw(_ mesh: YAMesh, instanceCount: Int) {
        for submesh in mesh.submeshes {
            drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBufferView.buffer, indexBufferOffset: submesh.indexBufferView.offset, instanceCount: instanceCount)
        }
    }
}

extension YAMesh {
    init(label: String? = nil, mdlMesh: MDLMesh, device: MTLDevice) throws {
        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: device)
        let submeshes = mtkMesh.submeshes.map { mtkSubmesh in
            let indexBufferView = BufferView(label: nil, buffer: mtkSubmesh.indexBuffer.buffer, offset: mtkSubmesh.indexBuffer.offset)
            return Submesh(label: mtkSubmesh.name, indexType: mtkSubmesh.indexType, indexBufferView: indexBufferView, indexCount: mtkSubmesh.indexCount, primitiveType: mtkSubmesh.primitiveType)
        }
        let vertexDescriptor = try VertexDescriptor(mdlMesh.vertexDescriptor)
        let vertexBufferViews = mtkMesh.vertexBuffers.map { BufferView(buffer: $0.buffer, offset: $0.offset) }
        self = .init(label: label, submeshes: submeshes, vertexDescriptor: vertexDescriptor, vertexBufferViews: vertexBufferViews)
    }
}
