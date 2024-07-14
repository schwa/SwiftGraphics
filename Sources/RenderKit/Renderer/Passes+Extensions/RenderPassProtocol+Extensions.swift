import BaseSupport
import Foundation
import Metal

public extension RenderPassProtocol {
    func sizeWillChange(device: MTLDevice, size: SIMD2<Float>, state: inout State) throws {
    }

    func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, state: State) throws {
        let commandEncoder = try commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        defer {
            commandEncoder.endEncoding()
        }
        try commandEncoder.withDebugGroup("Start encoding for \(type(of: self))") {
            commandEncoder.label = "\(type(of: self))"
            try encode(commandEncoder: commandEncoder, info: info, state: state)
        }
    }
}

// MARK: -

public extension RenderPassProtocol {
    func sizeWillChange(device: MTLDevice, size: SIMD2<Float>, untypedState: inout any PassState) throws {
        guard var state = untypedState as? State else {
            fatalError()
        }
        try sizeWillChange(device: device, size: size, state: &state)
        untypedState = state
    }

    func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, untypedState: any PassState) throws {
        guard let state = untypedState as? State else {
            fatalError()
        }
        try render(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor, info: info, state: state)
    }
}
