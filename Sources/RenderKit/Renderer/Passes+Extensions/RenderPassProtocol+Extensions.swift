import BaseSupport
import Foundation
import Metal

public extension RenderPassProtocol {
    func sizeWillChange(device: MTLDevice, state: inout State, size: CGSize) throws {
    }

    func render(commandBuffer: MTLCommandBuffer, state: inout State, drawableSize: SIMD2<Float>, renderPassDescriptor: MTLRenderPassDescriptor) throws {
        let commandEncoder = try commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        defer {
            commandEncoder.endEncoding()
        }
        try commandEncoder.withDebugGroup("Start encoding for \(type(of: self))") {
            commandEncoder.label = "\(type(of: self))"
            try encode(commandEncoder: commandEncoder, state: &state, drawableSize: drawableSize)
        }
    }
}

// MARK: -

public extension RenderPassProtocol {
    func sizeWillChange(device: MTLDevice, untypedState: inout any PassState, size: CGSize) throws {
        guard var state = untypedState as? State else {
            fatalError()
        }
        try sizeWillChange(device: device, state: &state, size: size)
        untypedState = state
    }

    func render(commandBuffer: MTLCommandBuffer, untypedState: inout any PassState, drawableSize: SIMD2<Float>, renderPassDescriptor: MTLRenderPassDescriptor) throws {
        guard var state = untypedState as? State else {
            fatalError()
        }
        try render(commandBuffer: commandBuffer, state: &state, drawableSize: drawableSize, renderPassDescriptor: renderPassDescriptor)
        untypedState = state
    }
}
