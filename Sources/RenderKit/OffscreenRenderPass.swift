import CoreGraphics
import Metal
import MetalKit
import MetalSupport
import ModelIO
import simd
import SIMDSupport
import SwiftUI

public struct OffscreenRenderPassConfiguration: MetalConfiguration {
    public let size: CGSize
    public let device: MTLDevice

    public var colorPixelFormat: MTLPixelFormat = .bgra8Unorm
    public var clearColor: MTLClearColor = .init(red: 0, green: 0, blue: 0, alpha: 1.0)
    public var depthStencilPixelFormat: MTLPixelFormat = .invalid
    public var depthStencilStorageMode: MTLStorageMode = .shared
    public var clearDepth: Double = 1.0

    public var currentRenderPassDescriptor: MTLRenderPassDescriptor?
    public var targetTexture: MTLTexture?

    public init(device: MTLDevice, size: CGSize) {
        self.device = device
        self.size = size
    }

    public mutating func update() {
        currentRenderPassDescriptor = nil
        targetTexture = nil

        let currentRenderPassDescriptor = MTLRenderPassDescriptor()

        let targetTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: colorPixelFormat, width: Int(size.width), height: Int(size.height), mipmapped: false)
        targetTextureDescriptor.storageMode = .shared
        targetTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        let targetTexture = device.makeTexture(descriptor: targetTextureDescriptor)!
        targetTexture.label = "Target Texture"
        currentRenderPassDescriptor.colorAttachments[0].texture = targetTexture
        currentRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        currentRenderPassDescriptor.colorAttachments[0].storeAction = .store
        self.targetTexture = targetTexture

        if depthStencilPixelFormat != .invalid {
            let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: depthStencilPixelFormat, width: Int(size.width), height: Int(size.height), mipmapped: false)
            depthTextureDescriptor.storageMode = .private
            depthTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            let depthStencilTexture = device.makeTexture(descriptor: depthTextureDescriptor)!
            depthStencilTexture.label = "Depth Texture"
            currentRenderPassDescriptor.depthAttachment.texture = depthStencilTexture
            currentRenderPassDescriptor.depthAttachment.loadAction = .clear
            currentRenderPassDescriptor.depthAttachment.storeAction = .store
        }

        self.currentRenderPassDescriptor = currentRenderPassDescriptor
    }
}

public extension RenderPass {
    func snapshot(device: MTLDevice, size: CGSize) async throws -> CGImage {
        var configuration = OffscreenRenderPassConfiguration(device: device, size: size)
        configuration.colorPixelFormat = .bgra8Unorm_srgb
        configuration.depthStencilPixelFormat = .depth16Unorm
        configuration.update()
        try setup(device: device, configuration: &configuration)
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError()
        }
        try commandQueue.withCommandBuffer(waitAfterCommit: true) { commandBuffer in
            try draw(device: device, size: size, renderPassDescriptor: configuration.currentRenderPassDescriptor!, commandBuffer: commandBuffer)
        }
        let cgImage = await configuration.targetTexture!.cgImage(colorSpace: CGColorSpace(name: CGColorSpace.extendedSRGB))
        return cgImage
    }
}
