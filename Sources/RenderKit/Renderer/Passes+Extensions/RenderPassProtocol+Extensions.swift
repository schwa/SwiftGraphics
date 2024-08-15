import BaseSupport
import Foundation
import Metal

public extension RenderPassProtocol {
    func drawableSizeWillChange(device: MTLDevice, size: SIMD2<Float>, state: inout State) throws {
    }
}

// MARK: -

public extension RenderPassProtocol {
    func drawableSizeWillChange(device: MTLDevice, size: SIMD2<Float>, untypedState: inout any Sendable) throws {
        guard var state = untypedState as? State else {
            throw BaseError.error(.typeMismatch)
        }
        try drawableSizeWillChange(device: device, size: size, state: &state)
        untypedState = state
    }

    func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, untypedState: any Sendable) throws {
        guard let state = untypedState as? State else {
            throw BaseError.error(.typeMismatch)
        }
        try render(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor, info: info, state: state)
    }
}
