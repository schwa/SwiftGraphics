import BaseSupport
import CoreGraphics
import Metal
import MetalSupport

public struct OffscreenRenderer {
    var device: MTLDevice
    var size: CGSize
    var offscreenConfiguration: OffscreenRenderPassConfiguration
    var renderPassDescriptor: MTLRenderPassDescriptor
    var renderer: Renderer<OffscreenRenderPassConfiguration>

    public var targetTexture: MTLTexture? {
        fatalError()
    }

    public init(device: MTLDevice, size: CGSize, offscreenConfiguration: OffscreenRenderPassConfiguration, renderPassDescriptor: MTLRenderPassDescriptor, passes: [any PassProtocol]) throws {
        self.device = device
        self.size = size
        self.offscreenConfiguration = offscreenConfiguration
        self.renderPassDescriptor = renderPassDescriptor
        self.renderer = .init(device: device, passes: .init(passes))
    }

    public mutating func configure() throws {
        try renderer.configure(&offscreenConfiguration)
        try renderer.sizeWillChange(size)
    }

    public mutating func render() throws {
        try device.capture(enabled: false) {
            let commandQueue = try device.makeCommandQueue().safelyUnwrap(MetalSupportError.resourceCreationFailure)
            try commandQueue.withCommandBuffer(waitAfterCommit: true) { commandBuffer in
                try renderer.render(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor, drawableSize: size)
            }
        }
    }
}

// MARK: -

public struct OffscreenRenderPassConfiguration: MetalConfigurationProtocol {
    public var colorPixelFormat: MTLPixelFormat = .bgra8Unorm
    public var clearColor: MTLClearColor = .init(red: 0, green: 0, blue: 0, alpha: 1.0)
    public var depthStencilPixelFormat: MTLPixelFormat = .invalid // TODO: NOT USED
    public var depthStencilStorageMode: MTLStorageMode = .shared // TODO: NOT USED
    public var clearDepth: Double = 1.0

    public init() {

    }

//    public var currentRenderPassDescriptor: MTLRenderPassDescriptor?
////    public var targetTexture: MTLTexture? // TODO: Rename - this is too vague
//
//    public mutating func update() throws {
//        currentRenderPassDescriptor = nil
//        targetTexture = nil
//    }
}
