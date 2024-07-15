import BaseSupport
import CoreGraphicsSupport
import Metal
import MetalFX
import MetalKit
import MetalSupport
import RenderKit
import simd
import SIMDSupport
import SwiftUI
#if os(iOS)
import UIKit
#endif

public struct GaussianSplatRenderView: View {
    private let scene: SceneGraph
    private let debugMode: Bool
    private let sortRate: Int

    @State
    private var size: CGSize = .zero

    @State
    private var colorTexture: MTLTexture?

    public init(scene: SceneGraph, debugMode: Bool, sortRate: Int) {
        self.scene = scene
        self.debugMode = debugMode
        self.sortRate = sortRate
    }

    public var body: some View {
        RenderView(passes: passes) { configuration in
            configuration.colorPixelFormat = .bgra8Unorm_srgb
            configuration.depthStencilPixelFormat = .invalid
            #if os(iOS)
            // TODO: FIXME
            print("### WARNING: isIdleTimerDisabled = true")
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
            //            print(size)
        }
        sizeWillChange: { device, configuration, size in
            do {
                let colorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: configuration.colorPixelFormat, width: Int(ceil(size.width / 2)), height: Int(ceil(size.height / 2)), mipmapped: false)
                colorTextureDescriptor.storageMode = .private
                let colorTexture = try device.makeTexture(descriptor: colorTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
                colorTexture.label = "reduce-resolution-color"
                self.colorTexture = colorTexture
            }
            catch {
                fatalError("Failed to create texture.")
            }
        }
        .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
        //            .toolbar {
        //                // TODO: this should not be here.
        //                Button("Screenshot") {
        //                    screenshot()
        //                }
        //            }
    }

    var passes: [any PassProtocol] {
        [GaussianSplatCompositePass(id: "GaussianSplatCompositePass", scene: scene, sortRate: sortRate)]
    }

    func screenshot() {
        do {
            let device = MTLCreateSystemDefaultDevice().forceUnwrap()
            let width = 1280
            let height = 960
            let pixelFormat = MTLPixelFormat.bgra8Unorm_srgb

            var offscreenConfiguration = OffscreenRenderPassConfiguration()
            offscreenConfiguration.clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
            offscreenConfiguration.depthStencilPixelFormat = .depth32Float
            offscreenConfiguration.depthStencilStorageMode = .memoryless
            offscreenConfiguration.clearDepth = 1
            offscreenConfiguration.colorPixelFormat = pixelFormat

            let renderPassDescriptor = MTLRenderPassDescriptor()

            let targetTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
            targetTextureDescriptor.storageMode = .shared
            targetTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            let targetTexture = try device.makeTexture(descriptor: targetTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
            targetTexture.label = "Target Texture"
            renderPassDescriptor.colorAttachments[0].texture = targetTexture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

            let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: width, height: height, mipmapped: false)
            depthTextureDescriptor.storageMode = .memoryless
            depthTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            let depthStencilTexture = try device.makeTexture(descriptor: depthTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
            depthStencilTexture.label = "Depth Texture"
            renderPassDescriptor.depthAttachment.texture = depthStencilTexture
            renderPassDescriptor.depthAttachment.loadAction = .clear
            renderPassDescriptor.depthAttachment.storeAction = .store
            renderPassDescriptor.depthAttachment.clearDepth = 1

            var passes = passes

            let upscaledPrivateTextureDescriptor = MTLTextureDescriptor()
            upscaledPrivateTextureDescriptor.pixelFormat = pixelFormat
            upscaledPrivateTextureDescriptor.width = width * 2
            upscaledPrivateTextureDescriptor.height = height * 2
            upscaledPrivateTextureDescriptor.storageMode = .private
            upscaledPrivateTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            let upscaledPrivateTexture = try device.makeTexture(descriptor: upscaledPrivateTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
            let spatialUpscalingPass = SpatialUpscalingPass(id: "SpatialUpscalingPass", inputTexture: targetTexture, outputTexture: upscaledPrivateTexture, colorProcessingMode: .perceptual)

            let upscaledSharedTextureDescriptor = upscaledPrivateTextureDescriptor
            upscaledSharedTextureDescriptor.storageMode = .shared
            let upscaledSharedTexture = try device.makeTexture(descriptor: upscaledSharedTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)

            let blitPass = BlitTexturePass(id: "BlitTexturePass", source: upscaledPrivateTexture, destination: upscaledSharedTexture)

            passes += [spatialUpscalingPass, blitPass]

            var offscreenRenderer = try OffscreenRenderer(device: device, size: SIMD2<Float>(Float(width), Float(height)), offscreenConfiguration: offscreenConfiguration, renderPassDescriptor: renderPassDescriptor, passes: passes)
            try offscreenRenderer.configure()
            try offscreenRenderer.render(capture: false)

            try targetTexture.cgImage().write(to: URL(filePath: "/tmp/test.png"))
            try upscaledSharedTexture.cgImage().write(to: URL(filePath: "/tmp/test-upscaled.png"))
            URL(filePath: "/tmp/test.png").reveal()
        }
        catch {
            fatalError("\(error)")
        }
    }
}
