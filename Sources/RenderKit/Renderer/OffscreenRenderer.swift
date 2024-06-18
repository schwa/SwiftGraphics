import CoreGraphics
import Metal
import SwiftGraphicsSupport

public struct OffscreenRenderer {
    public private(set) var size: CGSize
    public private(set) var device: MTLDevice // TODO: remove
    public private(set) var renderPasses: [any RenderPassProtocol]
    private var renderPassDescriptor: MTLRenderPassDescriptor
    private var stateByPasses: [AnyHashable: PassState]! // TODO: !
    private var commandQueue: MTLCommandQueue! // TODO: !

    public init(size: CGSize, device: MTLDevice, commandQueue: MTLCommandQueue? = nil, renderPasses: [any RenderPassProtocol]) throws {
        self.size = size
        self.device = device
        self.renderPasses = renderPasses
        self.renderPassDescriptor = MTLRenderPassDescriptor()
    }

    public mutating func addColorAttachment(at index: Int, texture: MTLTexture, clearColor: MTLClearColor) {
        renderPassDescriptor.colorAttachments[index].texture = texture
        renderPassDescriptor.colorAttachments[index].clearColor = clearColor
    }

    public mutating func addDepthAttachment(texture: MTLTexture, clearDepth: Double) {
        renderPassDescriptor.depthAttachment.texture = texture
        renderPassDescriptor.depthAttachment.clearDepth = clearDepth
    }

    public func colorAttachmentTexture(at index: Int) -> MTLTexture? {
        renderPassDescriptor.colorAttachments[index].texture
    }

    public func depthAttachmentTexture() -> MTLTexture? {
        renderPassDescriptor.depthAttachment.texture
    }

    public mutating func prepare() throws {
        let colorPixelFormat = renderPassDescriptor.colorAttachments[0].texture!.pixelFormat
        let depthAttachmentPixelFormat = renderPassDescriptor.depthAttachment.texture?.pixelFormat ?? .invalid

        stateByPasses = [:]
        for renderPass in renderPasses {
            let renderPipelineDescriptor = {
                let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
                renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
                renderPipelineDescriptor.depthAttachmentPixelFormat = depthAttachmentPixelFormat
                return renderPipelineDescriptor
            }

            let state = try renderPass.setup(device: device, renderPipelineDescriptor: renderPipelineDescriptor)
            stateByPasses[renderPass.id] = state
        }
        for renderPass in renderPasses {
            var state = stateByPasses[renderPass.id]!
            try renderPass.sizeWillChange(device: device, untypedState: &state, size: size)
            stateByPasses[renderPass.id] = state
        }

        self.commandQueue = commandQueue ?? device.makeCommandQueue().forceUnwrap("Could not make command queue")
        if self.commandQueue.label == nil {
            self.commandQueue.label = "OffscreenRenderer"
        }
    }

    public mutating func render(waitAfterCommit: Bool = true) throws {
        try device.capture {
            let renderPassDescriptor = renderPassDescriptor.typedCopy()
            try commandQueue.withCommandBuffer(waitAfterCommit: waitAfterCommit) { commandBuffer in
                commandBuffer.label = "OffscreenRenderer"

                for (index, renderPass) in renderPasses.enumerated() {
                    let isFirst = index == renderPasses.startIndex
                    let isLast = index == renderPasses.endIndex - 1

                    if isFirst {
                        renderPassDescriptor.colorAttachments[0].loadAction = .clear
                        renderPassDescriptor.depthAttachment.loadAction = .clear
                    }
                    else {
                        renderPassDescriptor.colorAttachments[0].loadAction = .load
                        renderPassDescriptor.depthAttachment.loadAction = .load
                    }

                    if isLast {
                        renderPassDescriptor.colorAttachments[0].storeAction = .store
                        renderPassDescriptor.depthAttachment.storeAction = .dontCare
                    }
                    else {
                        renderPassDescriptor.colorAttachments[0].storeAction = .store
                        renderPassDescriptor.depthAttachment.storeAction = .store
                    }

                    guard let state = stateByPasses[renderPass.id] else {
                        fatalError()
                    }

                    try renderPass.render(device: device, untypedState: state, drawableSize: SIMD2<Float>(size), renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
                }
            }
        }
    }
}

public extension MTLDevice {
    func capture <R>(enabled: Bool = true, _ block: () throws -> R) rethrows -> R {
        guard enabled else {
            return try block()
        }
        let captureManager = MTLCaptureManager.shared()
        let captureScope = captureManager.makeCaptureScope(device: self)
        let captureDescriptor = MTLCaptureDescriptor()
        captureDescriptor.captureObject = captureScope
        try! captureManager.startCapture(with: captureDescriptor)
        captureScope.begin()
        defer {
            captureScope.end()
        }
        return try block()
    }
}

//// If we capture (i.e. debug) the render pipeline, we have to do some setup here...
// var captureScope: MTLCaptureScope?
// if capture {
//    let captureDescriptor = MTLCaptureDescriptor()
//    captureDescriptor.captureObject = captureScope
//    try! captureManager.startCapture(with: captureDescriptor)
//    captureScope?.begin()
// }
//        captureScope?.end()

///// Enable this to capture the frame in Xcode Metal debugger.
// var capture = false

extension MTLDevice {
    func newBufferFor2DTexture(pixelFormat: MTLPixelFormat, size: MTLSize) -> MTLBuffer {
        assert(size.depth == 1)
        let bytesPerPixel = pixelFormat.bits! / 8
        let alignment = minimumLinearTextureAlignment(for: pixelFormat)
        let bytesPerRow = align(Int(size.width) * bytesPerPixel, alignment: alignment)
        guard let buffer = makeBuffer(length: bytesPerRow * Int(size.height), options: .storageModeShared) else {
            fatalError("Could not create buffer.")
        }
        return buffer
    }

    public func makeColorTexture(size: CGSize, pixelFormat: MTLPixelFormat) throws -> MTLTexture {
        // Create a shared memory MTLBuffer for the color attachment texture. This allows us to access the pixels efficiently from CPU later on (which is likely the whole point of an offscreen renderer).
        let colorAttachmentTextureBuffer = newBufferFor2DTexture(pixelFormat: pixelFormat, size: MTLSize(width: Int(size.width), height: Int(size.height), depth: 1))

        // Now create a texture descriptor and texture from the buffer
        let colorAttachmentTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: Int(size.width), height: Int(size.height), mipmapped: false)
        colorAttachmentTextureDescriptor.storageMode = .shared
        colorAttachmentTextureDescriptor.usage = [.renderTarget]

        let bytesPerPixel = pixelFormat.bits! / 8
        let alignment = minimumLinearTextureAlignment(for: pixelFormat)
        let bytesPerRow = align(Int(size.width) * bytesPerPixel, alignment: alignment)
        let colorAttachmentTexture = colorAttachmentTextureBuffer.makeTexture(descriptor: colorAttachmentTextureDescriptor, offset: 0, bytesPerRow: bytesPerRow)!
        colorAttachmentTexture.label = "Color Texture"
        return colorAttachmentTexture
    }

    public func makeDepthTexture(size: CGSize, depthStencilPixelFormat: MTLPixelFormat, memoryless: Bool) throws -> MTLTexture {
        // ... and if we had a depth buffer - do the same... except depth buffers can be memoryless (yay) and we .dontCare about storing them later.
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: depthStencilPixelFormat, width: Int(size.width), height: Int(size.height), mipmapped: false)
        depthTextureDescriptor.storageMode = .memoryless
        depthTextureDescriptor.usage = .renderTarget
        let depthStencilTexture = makeTexture(descriptor: depthTextureDescriptor)!
        depthStencilTexture.label = "Depth Texture"
        return depthStencilTexture
    }}
