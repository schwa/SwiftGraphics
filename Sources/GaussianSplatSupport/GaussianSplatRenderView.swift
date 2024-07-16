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
    private var colorTexture: MTLTexture? // TODO: RENAME

    @State
    private var upscaledTexture: MTLTexture? // TODO: RENAME

    @State
    private var drawableSize: SIMD2<Float> = .zero

    public init(scene: SceneGraph, debugMode: Bool, sortRate: Int) {
        self.scene = scene
        self.debugMode = debugMode
        self.sortRate = sortRate
    }

    public var body: some View {
        RenderView(passes: pass.map { [$0] }?? []) { configuration in
            configuration.colorPixelFormat = .bgra8Unorm_srgb
            configuration.depthStencilPixelFormat = .invalid
            configuration.framebufferOnly = false
            #if os(iOS)
            // TODO: FIXME
            print("### WARNING: isIdleTimerDisabled = true")
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
            //            print(size)
        }
        sizeWillChange: { device, configuration, size in
            do {
                drawableSize = SIMD2<Float>(size)

                let colorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: configuration.colorPixelFormat, width: Int(ceil(size.width / 4)), height: Int(ceil(size.height / 4)), mipmapped: false)
                colorTextureDescriptor.storageMode = .private
                colorTextureDescriptor.usage = [.renderTarget, .shaderRead]
                let colorTexture = try device.makeTexture(descriptor: colorTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
                colorTexture.label = "reduce-resolution-color"
                self.colorTexture = colorTexture

                let upscaledTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: configuration.colorPixelFormat, width: Int(ceil(size.width)), height: Int(ceil(size.height)), mipmapped: false)
                upscaledTextureDescriptor.storageMode = .private
                upscaledTextureDescriptor.usage = .renderTarget
                let upscaledTexture = try device.makeTexture(descriptor: upscaledTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
                upscaledTexture.label = "reduce-resolution-upscaled"
                self.upscaledTexture = upscaledTexture
            }
            catch {
                fatalError("Failed to create texture.")
            }
        }
        //            .toolbar {
        //                // TODO: this should not be here.
        //                Button("Screenshot") {
        //                    screenshot()
        //                }
        //            }
    }

    var pass: (GroupPass)? {
        guard let colorTexture, let upscaledTexture else {
            print("No texture(s)")
            return nil
        }
        guard let splatsNode = scene.node(for: "splats"), let splats = splatsNode.content as? SplatCloud else {
            print("No splats")
            return nil
        }
        guard let cameraNode = scene.node(for: "camera") else {
            print("No camera")
            return nil
        }

        let offscreenRenderPassDescriptor = MTLRenderPassDescriptor()
        offscreenRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        offscreenRenderPassDescriptor.colorAttachments[0].texture = colorTexture
        offscreenRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        offscreenRenderPassDescriptor.colorAttachments[0].storeAction = .store

        return GroupPass(id: "TODO-1") {
            GroupPass(id: "GaussianSplatRenderGroup", renderPassDescriptor: offscreenRenderPassDescriptor) {
                GaussianSplatPreCalcComputePass(
                    splats: splats,
                    modelMatrix: simd_float3x3(truncating: splatsNode.transform.matrix),
                    cameraPosition: cameraNode.transform.translation
                )
                GaussianSplatBitonicSortComputePass(
                    splats: splats,
                    sortRate: sortRate
                )
                GaussianSplatRenderPass(
                    scene: scene,
                    debugMode: false
                )
            }
            SpatialUpscalingPass(id: "TODO-2", source: colorTexture, destination: upscaledTexture, colorProcessingMode: .perceptual)
            BlitTexturePass(id: "TODO-3", source: upscaledTexture, destination: nil)
        }
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

            //            var passes: [any PassProtocol] = [pass]

            let upscaledPrivateTextureDescriptor = MTLTextureDescriptor()
            upscaledPrivateTextureDescriptor.pixelFormat = pixelFormat
            upscaledPrivateTextureDescriptor.width = width * 2
            upscaledPrivateTextureDescriptor.height = height * 2
            upscaledPrivateTextureDescriptor.storageMode = .private
            upscaledPrivateTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            let upscaledPrivateTexture = try device.makeTexture(descriptor: upscaledPrivateTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
            //            let spatialUpscalingPass = SpatialUpscalingPass(id: "SpatialUpscalingPass", inputTexture: targetTexture, outputTexture: upscaledPrivateTexture, colorProcessingMode: .perceptual)
            //
            //            let upscaledSharedTextureDescriptor = upscaledPrivateTextureDescriptor
            //            upscaledSharedTextureDescriptor.storageMode = .shared
            //            let upscaledSharedTexture = try device.makeTexture(descriptor: upscaledSharedTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
            //
            //            let blitPass = BlitTexturePass(id: "BlitTexturePass", source: upscaledPrivateTexture, destination: upscaledSharedTexture)

            //            passes += [spatialUpscalingPass, blitPass]

            //            var offscreenRenderer = try OffscreenRenderer(device: device, size: SIMD2<Float>(Float(width), Float(height)), offscreenConfiguration: offscreenConfiguration, renderPassDescriptor: renderPassDescriptor, passes: passes)
            //            try offscreenRenderer.configure()
            //            try offscreenRenderer.render(capture: false)
            //
            //            try targetTexture.cgImage().write(to: URL(filePath: "/tmp/test.png"))
            //            try upscaledSharedTexture.cgImage().write(to: URL(filePath: "/tmp/test-upscaled.png"))
            //            URL(filePath: "/tmp/test.png").reveal()
        }
        catch {
            fatalError("\(error)")
        }
    }
}
