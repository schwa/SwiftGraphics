import BaseSupport
import Foundation
import Metal

public extension RenderPassProtocol {
    func drawableSizeWillChange(device: MTLDevice, size: SIMD2<Float>, state: inout State) throws {
    }
}

// MARK: -

public extension RenderPassProtocol {
    func drawableSizeWillChange(device: MTLDevice, size: SIMD2<Float>, untypedState: inout any PassState) throws {
        guard var state = untypedState as? State else {
            throw BaseError.typeMismatch
        }
        try drawableSizeWillChange(device: device, size: size, state: &state)
        untypedState = state
    }

    func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, untypedState: any PassState) throws {
        guard let state = untypedState as? State else {
            throw BaseError.typeMismatch
        }
        try render(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor, info: info, state: state)
    }
}
