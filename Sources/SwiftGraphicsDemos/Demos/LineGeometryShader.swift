

import Metal
import RenderKit

struct LineShaderRenderPass: RenderPassProtocol {
    struct State: Sendable {

    }

    var id: PassID

    func setup(device: any MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        State()
    }

    func render(commandBuffer: any MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: RenderKit.PassInfo, state: State) throws {
    }
}
