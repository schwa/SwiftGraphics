import ModelIO

// TODO: This has a silly name but is very useful. Rename.
nonisolated(unsafe) public let oneTrueVertexDescriptor: MDLVertexDescriptor = {
    let vertexDescriptor = MDLVertexDescriptor()
    vertexDescriptor.addOrReplaceAttribute(.init(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0))
    vertexDescriptor.addOrReplaceAttribute(.init(name: MDLVertexAttributeNormal, format: .float3, offset: 0, bufferIndex: 0))
    vertexDescriptor.addOrReplaceAttribute(.init(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 0, bufferIndex: 0))
    vertexDescriptor.setPackedOffsets()
    vertexDescriptor.setPackedStrides()
    return vertexDescriptor
}()
