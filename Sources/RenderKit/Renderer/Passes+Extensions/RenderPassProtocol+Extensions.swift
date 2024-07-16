import BaseSupport
import Foundation
import Metal
import MetalSupport

public extension RenderPassProtocol {
    func sizeWillChange(device: MTLDevice, size: SIMD2<Float>, state: inout State) throws {
    }

    func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, state: State) throws {
        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "\(type(of: self))") { commandEncoder in
            try commandEncoder.withDebugGroup("Start encoding for \(type(of: self))") {
                try encode(commandEncoder: commandEncoder, info: info, state: state)
            }
        }
    }
}

// MARK: -

public extension RenderPassProtocol {
    func sizeWillChange(device: MTLDevice, size: SIMD2<Float>, untypedState: inout any PassState) throws {
        guard var state = untypedState as? State else {
            fatalError("Could not cast state to `State`, are two passes using same identifier?")
        }
        try sizeWillChange(device: device, size: size, state: &state)
        untypedState = state
    }

    func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, untypedState: any PassState) throws {
        guard let state = untypedState as? State else {
            fatalError("Could not cast state to `State`, are two passes using same identifier?")
        }
        try render(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor, info: info, state: state)
    }
}
