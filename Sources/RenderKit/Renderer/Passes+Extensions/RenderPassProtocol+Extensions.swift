import BaseSupport
import Foundation
import Metal

public extension RenderPassProtocol {
    func sizeWillChange(device: MTLDevice, state: inout State, size: CGSize) throws {
    }

    func render(device: MTLDevice, state: inout State, drawableSize: SIMD2<Float>, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) throws {
        let commandEncoder = try commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        defer {
            commandEncoder.endEncoding()
        }
        try commandEncoder.withDebugGroup("Start encoding for \(type(of: self))") {
            commandEncoder.label = "\(type(of: self))"
            try encode(device: device, state: &state, drawableSize: drawableSize, commandEncoder: commandEncoder)
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

    func render(device: MTLDevice, untypedState: inout any PassState, drawableSize: SIMD2<Float>, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) throws {
        guard var state = untypedState as? State else {
            fatalError()
        }
        try render(device: device, state: &state, drawableSize: drawableSize, renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
        untypedState = state
    }
}
