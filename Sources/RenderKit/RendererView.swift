#if !os(visionOS)
import MetalSupport
import MetalUISupport
import SwiftUI

@available(*, deprecated, message: "Deprecated")
public struct RendererView<T>: View where T: RenderPass {
    // TODO: Does this _really_ need to be a Binding?
    @Binding
    var renderPass: T

    @State
    var commandQueue: MTLCommandQueue?

    @Environment(\.metalDevice)
    var device

    public init(renderPass: Binding<T>) {
        _renderPass = renderPass
    }

    public var body: some View {
        MetalView { device, configuration in
            configuration.preferredFramesPerSecond = 120
            configuration.colorPixelFormat = .bgra8Unorm_srgb
            configuration.depthStencilPixelFormat = .depth16Unorm
            configuration.depthStencilStorageMode = .memoryless
            try renderPass.setup(device: device, configuration: &configuration)
        } drawableSizeWillChange: { device, _, size in
            try renderPass.drawableSizeWillChange(device: device, size: size)
        } draw: { device, _, size, currentDrawable, renderPassDescriptor in
            guard let commandQueue else {
                fatalError("Draw called before command queue set up. This should be impossible.")
            }
            try commandQueue.withCommandBuffer(drawable: currentDrawable, block: { commandBuffer in
                commandBuffer.label = "RendererView-CommandBuffer"
                try renderPass.draw(device: device, size: size, renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
            })
        }
        .onAppear {
            if commandQueue == nil {
                commandQueue = device.makeCommandQueue()
            }
        }
    }
}
#endif
