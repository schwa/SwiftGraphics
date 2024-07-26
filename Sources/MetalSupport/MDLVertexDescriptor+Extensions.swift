import ModelIO

public extension MDLVertexDescriptor {
    /// A basic vertex descriptor with float-based position, normal and texture coordinates all in a single buffer.
    static var simpleVertexDescriptor: MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.addOrReplaceAttribute(.init(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0))
        vertexDescriptor.addOrReplaceAttribute(.init(name: MDLVertexAttributeNormal, format: .float3, offset: 0, bufferIndex: 0))
        vertexDescriptor.addOrReplaceAttribute(.init(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 0, bufferIndex: 0))
        vertexDescriptor.setPackedOffsets()
        vertexDescriptor.setPackedStrides()
        return vertexDescriptor
    }
}
