import Algorithms
import MetalSupport
import ModelIO
import SIMDSupport

enum TrivialMeshError: Error {
    case generic(String)
}

public extension TrivialMesh where Vertex == SIMD3<Float> {
    init(url: URL) throws {
        let asset = MDLAsset(url: url)
        let mesh = asset.object(at: 0) as! MDLMesh
        let positions = try mesh.positions
        // TODO: confirm that these are triangles.
        // TODO: confirm that index is uint32
        let submesh = mesh.submeshes![0] as! MDLSubmesh
        let indexBuffer = submesh.indexBuffer
        let indexBytes = UnsafeRawBufferPointer(start: indexBuffer.map().bytes, count: indexBuffer.length)
        let indices = indexBytes.bindMemory(to: UInt32.self).map { Int($0) }

        self.init(indices: Array(indices), vertices: Array(positions.map { SIMD3<Float>($0) }))
    }
}

public extension TrivialMesh where Vertex == SimpleVertex {
    init(url: URL) throws {
        let asset = MDLAsset(url: url)
        let mesh = asset.object(at: 0) as! MDLMesh
        let positions = try mesh.positions
        let normals: [PackedFloat3] = if mesh.hasNormals {
            try mesh.normals
        }
        else {
            Array(repeating: [0, 0, 0], count: positions.count)
        }
        let vertices = zip(positions, normals).map {
            SimpleVertex(packedPosition: $0.0, packedNormal: $0.1)
        }

        // TODO: confirm that these are triangles.
        // TODO: confirm that index is uint32
        let submesh = mesh.submeshes![0] as! MDLSubmesh
        let indexBuffer = submesh.indexBuffer
        let indexBytes = UnsafeRawBufferPointer(start: indexBuffer.map().bytes, count: indexBuffer.length)
        let indices = indexBytes.bindMemory(to: UInt32.self).map { Int($0) }

        self.init(indices: Array(indices), vertices: vertices)
    }
}

extension MDLMesh {
    var positions: [PackedFloat3] {
        get throws {
            guard let attribute = vertexDescriptor.attributes.compactMap({ $0 as? MDLVertexAttribute }).first(where: { $0.name == MDLVertexAttributePosition }) else {
                throw TrivialMeshError.generic("MDLMesh does not specify positions attribute.")
            }
            guard attribute.format == .float3 else {
                throw TrivialMeshError.generic("Expected attribute to be .float3")
            }
            let bufferLayout = vertexDescriptor.layouts[attribute.bufferIndex] as! MDLVertexBufferLayout
            let buffer = vertexBuffers[attribute.bufferIndex]
            let bytes = UnsafeRawBufferPointer(start: buffer.map().bytes, count: buffer.length)
            return bytes.chunks(stride: bufferLayout.stride, offset: attribute.offset, size: MemoryLayout<PackedFloat3>.stride).map {
                $0.load(as: PackedFloat3.self)
            }
        }
    }

    var hasNormals: Bool {
        guard vertexDescriptor.attributes.compactMap({ $0 as? MDLVertexAttribute }).contains(where: { $0.name == MDLVertexAttributeNormal }) else {
            return false
        }
        return true
    }

    var normals: [PackedFloat3] {
        get throws {
            guard let attribute = vertexDescriptor.attributes.compactMap({ $0 as? MDLVertexAttribute }).first(where: { $0.name == MDLVertexAttributeNormal }) else {
                throw TrivialMeshError.generic("MDLMesh does not specify normals attribute.")
            }
            guard attribute.format == .float3 else {
                throw TrivialMeshError.generic("Expected attribute to be .float3")
            }
            let bufferLayout = vertexDescriptor.layouts[attribute.bufferIndex] as! MDLVertexBufferLayout
            let buffer = vertexBuffers[attribute.bufferIndex]
            let bytes = UnsafeRawBufferPointer(start: buffer.map().bytes, count: buffer.length)
            return bytes.chunks(stride: bufferLayout.stride, offset: attribute.offset, size: MemoryLayout<PackedFloat3>.stride).map {
                $0.load(as: PackedFloat3.self)
            }
        }
    }
}

// TODO: Move
extension DataProtocol {
    func chunks(stride: Int, offset: Int, size: Int) -> AnySequence<SubSequence> {
        let r = chunks(ofCount: stride).lazy.map { slice in
            let start = slice.index(slice.startIndex, offsetBy: offset)
            let end = slice.index(start, offsetBy: size)
            return slice[start ..< end]
        }
        return AnySequence(r)
    }
}

public extension MDLMesh {
    convenience init(trivialMesh mesh: TrivialMesh<SimpleVertex>) {
        let vertexBuffer = mesh.vertices.withUnsafeBytes { buffer in
            MDLMeshBufferData(type: .vertex, data: Data(buffer))
        }
        let descriptor = MDLVertexDescriptor()
        // TODO: hard coded.
        descriptor.addOrReplaceAttribute(.init(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0))
        descriptor.addOrReplaceAttribute(.init(name: MDLVertexAttributeNormal, format: .float3, offset: 12, bufferIndex: 0))
        descriptor.addOrReplaceAttribute(.init(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 24, bufferIndex: 0))
        descriptor.setPackedOffsets()
        descriptor.setPackedStrides()
        let indexType: MDLIndexBitDepth
        let indexBuffer: MDLMeshBuffer
        switch mesh.indices.count {
        case 0 ..< 256:
            indexType = .uInt8
            let indices = mesh.indices.map({ UInt8($0) })
            indexBuffer = indices.withUnsafeBytes { buffer in
                MDLMeshBufferData(type: .index, data: Data(buffer))
            }
        case 256 ..< 65_536:
            indexType = .uInt16
            let indices = mesh.indices.map({ UInt16($0) })
            indexBuffer = indices.withUnsafeBytes { buffer in
                MDLMeshBufferData(type: .index, data: Data(buffer))
            }
        case 65_536 ..< 4_294_967_296:
            indexType = .uInt32
            let indices = mesh.indices.map({ UInt32($0) })
            indexBuffer = indices.withUnsafeBytes { buffer in
                MDLMeshBufferData(type: .index, data: Data(buffer))
            }
        default:
            fatalError()
        }
        let submesh = MDLSubmesh(indexBuffer: indexBuffer, indexCount: mesh.indices.count, indexType: indexType, geometryType: .triangles, material: nil)
        self.init(vertexBuffer: vertexBuffer, vertexCount: mesh.vertices.count, descriptor: descriptor, submeshes: [submesh])
    }
}

public extension TrivialMesh where Vertex == SimpleVertex {
    func write(to url: URL) throws {
        let asset = MDLAsset()
        let mesh = MDLMesh(trivialMesh: self)
        asset.add(mesh)
        try asset.export(to: url)
    }
}
