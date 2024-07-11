import CoreGraphics
import Metal
import MetalKit
import MetalSupport
import MetalUISupport
import ModelIO
import simd
import SIMDSupport
import SwiftUI

public struct OffscreenRenderPassConfiguration: MetalConfigurationProtocol {
    public let size: CGSize
    public let device: MTLDevice

    public var colorPixelFormat: MTLPixelFormat = .bgra8Unorm
    public var clearColor: MTLClearColor = .init(red: 0, green: 0, blue: 0, alpha: 1.0)
    public var depthStencilPixelFormat: MTLPixelFormat = .invalid // TODO: NOT USED
    public var depthStencilStorageMode: MTLStorageMode = .shared // TODO: NOT USED
    public var clearDepth: Double = 1.0

    public var currentRenderPassDescriptor: MTLRenderPassDescriptor?
    public var targetTexture: MTLTexture? // TODO: Rename - this is too vague

    public init(device: MTLDevice, size: CGSize) {
        self.device = device
        self.size = size
    }

    public mutating func update() throws {
        currentRenderPassDescriptor = nil
        targetTexture = nil
        let currentRenderPassDescriptor = MTLRenderPassDescriptor()
        // TODO: This configuration is way too basic.
        let targetTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: colorPixelFormat, width: Int(size.width), height: Int(size.height), mipmapped: false)
        targetTextureDescriptor.storageMode = .shared
        targetTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        let targetTexture = try device.makeTexture(descriptor: targetTextureDescriptor).safelyUnwrap(MetalSupportError.resourceCreationFailure)
        targetTexture.label = "Target Texture"
        currentRenderPassDescriptor.colorAttachments[0].texture = targetTexture
        currentRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        currentRenderPassDescriptor.colorAttachments[0].storeAction = .store
        currentRenderPassDescriptor.colorAttachments[0].clearColor = clearColor
        self.targetTexture = targetTexture

        if depthStencilPixelFormat != .invalid {
            let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: depthStencilPixelFormat, width: Int(size.width), height: Int(size.height), mipmapped: false)
            depthTextureDescriptor.storageMode = depthStencilStorageMode
            depthTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            let depthStencilTexture = try device.makeTexture(descriptor: depthTextureDescriptor).safelyUnwrap(MetalSupportError.resourceCreationFailure)
            depthStencilTexture.label = "Depth Texture"
            currentRenderPassDescriptor.depthAttachment.texture = depthStencilTexture
            currentRenderPassDescriptor.depthAttachment.loadAction = .clear
            currentRenderPassDescriptor.depthAttachment.storeAction = .store
            currentRenderPassDescriptor.depthAttachment.clearDepth = clearDepth
        }
        self.currentRenderPassDescriptor = currentRenderPassDescriptor
    }
}
