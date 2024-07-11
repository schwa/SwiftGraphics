import BaseSupport
import CoreGraphics
import Metal
import MetalSupport

public struct OffscreenRenderer {
    var device: MTLDevice
    var size: CGSize
    var offscreenConfiguration: OffscreenRenderPassConfiguration
    var renderer: Renderer<OffscreenRenderPassConfiguration>

    public var targetTexture: MTLTexture? {
        offscreenConfiguration.targetTexture
    }

    public init(device: MTLDevice, size: CGSize, passes: [any PassProtocol]) throws {
        self.device = device
        self.size = size
        offscreenConfiguration = OffscreenRenderPassConfiguration(device: device, size: size)
        offscreenConfiguration.clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
        offscreenConfiguration.depthStencilPixelFormat = .depth32Float
        offscreenConfiguration.depthStencilStorageMode = .memoryless
        offscreenConfiguration.clearDepth = 1
        offscreenConfiguration.colorPixelFormat = .bgra8Unorm_srgb
        try offscreenConfiguration.update()
        renderer = Renderer<OffscreenRenderPassConfiguration>(device: device, passes: .init(passes))
    }

    public mutating func configure() throws {
        try renderer.configure(&offscreenConfiguration)
        try renderer.sizeWillChange(size)
    }

    public mutating func render() throws {
        try device.capture(enabled: false) {
            let commandQueue = try device.makeCommandQueue().safelyUnwrap(MetalSupportError.resourceCreationFailure)
            try commandQueue.withCommandBuffer(waitAfterCommit: true) { commandBuffer in
                let renderPassDescriptor = try offscreenConfiguration.currentRenderPassDescriptor.safelyUnwrap(MetalSupportError.resourceCreationFailure)
                try renderer.render(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor, drawableSize: size)
            }
        }
    }
}
