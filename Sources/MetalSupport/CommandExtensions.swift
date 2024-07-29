import BaseSupport
import Metal
import MetalKit

public extension MTLCommandQueue {
    func withCommandBuffer<R>(descriptor: MTLCommandBufferDescriptor? = nil, waitAfterCommit wait: Bool, block: (MTLCommandBuffer) throws -> R) throws -> R {
        let descriptor = descriptor ?? .init()
        guard let commandBuffer = makeCommandBuffer(descriptor: descriptor) else {
            throw BaseError.resourceCreationFailure
        }
        defer {
            commandBuffer.commit()
            if wait {
                commandBuffer.waitUntilCompleted()
            }
        }
        return try block(commandBuffer)
    }

    func withCommandBuffer<R>(drawable: (any MTLDrawable)? = nil, block: (MTLCommandBuffer) throws -> R) throws -> R {
        guard let commandBuffer = makeCommandBuffer() else {
            throw BaseError.resourceCreationFailure
        }
        defer {
            if let drawable {
                commandBuffer.present(drawable)
            }
            commandBuffer.commit()
        }
        return try block(commandBuffer)
    }
}

// MARK: -

public extension MTLCommandBuffer {
    func withRenderCommandEncoder<R>(descriptor: MTLRenderPassDescriptor, label: String? = nil, useDebugGroup: Bool = false, block: (MTLRenderCommandEncoder) throws -> R) throws -> R {
        guard let renderCommandEncoder = makeRenderCommandEncoder(descriptor: descriptor) else {
            throw BaseError.resourceCreationFailure
        }
        if let label {
            renderCommandEncoder.label = label
        }
        defer {
            renderCommandEncoder.endEncoding()
        }
        return try renderCommandEncoder.withDebugGroup("Encode \(label ?? "RenderCommandEncoder")", enabled: useDebugGroup) {
            try block(renderCommandEncoder)
        }
    }
}

// MARK: -

public extension MTLCommandEncoder {
    func withDebugGroup<R>(_ string: String, enabled: Bool = true, _ closure: () throws -> R) rethrows -> R {
        if enabled {
            pushDebugGroup(string)
        }
        defer {
            if enabled {
                popDebugGroup()
            }
        }
        return try closure()
    }
}

// MARK: -

public extension MTLRenderCommandEncoder {
    func withDebugGroup<R>(_ string: String, block: () throws -> R) rethrows -> R {
        pushDebugGroup(string)
        defer {
            popDebugGroup()
        }
        return try block()
    }

    // @available(*, deprecated, message: "Deprecated. Clean this up.")
    func setVertexBuffersFrom(mesh: MTKMesh) {
        for (index, element) in mesh.vertexDescriptor.layouts.enumerated() {
            guard let layout = element as? MDLVertexBufferLayout else {
                return
            }
            // TODO: Is this a reliable test on any vertex descriptor?
            if layout.stride != 0 {
                let buffer = mesh.vertexBuffers[index]
                setVertexBuffer(buffer.buffer, offset: buffer.offset, index: index)
            }
        }
    }

    // @available(*, deprecated, message: "Deprecated. Clean this up.")
    func draw(_ mesh: MTKMesh, setVertexBuffers: Bool = true) {
        if setVertexBuffers {
            for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
                setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: index)
            }
        }
        for submesh in mesh.submeshes {
            drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        }
    }

    // @available(*, deprecated, message: "Deprecated. Clean this up.")
    func draw(_ mesh: MTKMesh, instanceCount: Int) {
        for submesh in mesh.submeshes {
            drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset, instanceCount: instanceCount)
        }
    }

    // @available(*, deprecated, message: "Deprecated. Clean this up.")
    func setVertexBuffer(_ mesh: MTKMesh, startingIndex: Int) {
        for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
            setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: startingIndex + index)
        }
    }
}
