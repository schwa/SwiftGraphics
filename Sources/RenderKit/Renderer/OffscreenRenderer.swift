import BaseSupport
import CoreGraphics
import Metal
import MetalSupport

public struct OffscreenRenderer {
    var device: MTLDevice
    var size: SIMD2<Float>
    var offscreenConfiguration: OffscreenRenderPassConfiguration
    var renderPassDescriptor: MTLRenderPassDescriptor
    var renderer: Renderer<OffscreenRenderPassConfiguration>

    public init(device: MTLDevice, size: SIMD2<Float>, offscreenConfiguration: OffscreenRenderPassConfiguration, renderPassDescriptor: MTLRenderPassDescriptor, passes: [any PassProtocol]) throws {
        self.device = device
        self.size = size
        self.offscreenConfiguration = offscreenConfiguration
        self.renderPassDescriptor = renderPassDescriptor
        self.renderer = .init(device: device, passes: .init(passes), logger: nil)
    }

    public mutating func configure() throws {
        try renderer.configure(&offscreenConfiguration)
        try renderer.drawableSizeWillChange(size)
    }

    public mutating func render(capture: Bool = false) throws {
        try device.capture(enabled: capture) {
            let commandQueue = try device.makeCommandQueue().safelyUnwrap(BaseError.resourceCreationFailure)
            try commandQueue.withCommandBuffer(waitAfterCommit: true) { commandBuffer in
                try renderer.render(commandBuffer: commandBuffer, currentRenderPassDescriptor: renderPassDescriptor, drawableSize: size)
            }
        }
    }
}

// MARK: -

public struct OffscreenRenderPassConfiguration: MetalConfigurationProtocol {
    public var colorPixelFormat: MTLPixelFormat = .bgra8Unorm
    public var clearColor: MTLClearColor = .init(red: 0, green: 0, blue: 0, alpha: 1.0)
    public var depthStencilPixelFormat: MTLPixelFormat = .invalid
    public var depthStencilStorageMode: MTLStorageMode = .shared
    public var clearDepth: Double = 1.0
    public var framebufferOnly: Bool = true

    public init() {
    }
}
