import BaseSupport
import Metal
#if !targetEnvironment(simulator)
import MetalFX
#endif
import MetalKit
import MetalSupport
import RenderKit
import RenderKitSceneGraph
import simd
import SIMDSupport
import SwiftUI
import SwiftUISupport
#if os(iOS)
import UIKit
#endif

public struct GaussianSplatRenderView <Splat>: View where Splat: SplatProtocol {
    private let scene: SceneGraph
    private let debugMode: Bool
    private let sortRate: Int
    private let metalFXRate: Float
    private let gpuCounters: GPUCounters?
    private let discardRate: Float

    @Environment(\.metalDevice)
    var device

    @Environment(\.logger)
    var logger

    @State
    private var colorTexture: MTLTexture? // TODO: RENAME

    @State
    private var upscaledTexture: MTLTexture? // TODO: RENAME

    @State
    private var drawableSize: SIMD2<Float> = .zero

    public init(scene: SceneGraph, debugMode: Bool = false, sortRate: Int = 0, metalFXRate: Float = 1, gpuCounters: GPUCounters? = nil, discardRate: Float = 0) {
        self.scene = scene
        self.debugMode = debugMode
        self.sortRate = sortRate
        self.metalFXRate = metalFXRate
        self.gpuCounters = gpuCounters
        self.discardRate = discardRate
    }

    public var body: some View {
        // swiftlint:disable:next force_try
        RenderView(pass: try! makePass()) { configuration in
            configuration.colorPixelFormat = .bgra8Unorm_srgb
            configuration.depthStencilPixelFormat = .invalid
            configuration.framebufferOnly = false
        }
        sizeWillChange: { device, configuration, size in
            do {
                let size = SIMD2<Float>(size)
                guard drawableSize != size else {
                    return
                }
                drawableSize = SIMD2<Float>(size)
                logger?.debug("\(type(of: self)).\(#function): \(drawableSize)")
                try makeMetalFXTextures(device: device, pixelFormat: configuration.colorPixelFormat, size: drawableSize)
            }
            catch {
                fatalError("Failed to create texture.")
            }
        }
        .onChange(of: metalFXRate) {
            do {
                try makeMetalFXTextures(device: device, pixelFormat: .bgra8Unorm_srgb, size: drawableSize)
            }
            catch {
                logger?.error("Failed to make metal textures: \(error)")
            }
        }
    }

    func makePass() throws -> GroupPass? {
        guard let colorTexture, let upscaledTexture else {
            return nil
        }
        guard let splatsNode = scene.firstNode(label: "splats"), let splats = splatsNode.content as? SplatCloud<Splat> else {
            return nil
        }
        guard let cameraNode = scene.firstNode(label: "camera") else {
            return nil
        }

        let offscreenRenderPassDescriptor = MTLRenderPassDescriptor()
        offscreenRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        offscreenRenderPassDescriptor.colorAttachments[0].texture = colorTexture
        offscreenRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        offscreenRenderPassDescriptor.colorAttachments[0].storeAction = .store

        return try GroupPass(id: "TODO-1") {
            GroupPass(id: "GaussianSplatRenderGroup", renderPassDescriptor: metalFXRate != 1 ? offscreenRenderPassDescriptor : nil) {
                if sortRate > 0 {
                    GaussianSplatDistanceComputePass(
                        splats: splats,
                        modelMatrix: simd_float3x3(truncating: splatsNode.transform.matrix),
                        cameraPosition: cameraNode.transform.translation,
                        sortRate: sortRate
                    )
                    GaussianSplatBitonicSortComputePass(
                        splats: splats,
                        sortRate: sortRate
                    )
                }
                GaussianSplatRenderPass<Splat>(
                    scene: scene,
                    debugMode: false,
                    discardRate: discardRate
                )
            }
            #if !targetEnvironment(simulator)
            if metalFXRate != 1 {
                try SpatialUpscalingPass(id: "TODO-2", device: device, source: colorTexture, destination: upscaledTexture, colorProcessingMode: .perceptual)
                BlitTexturePass(id: "TODO-3", source: upscaledTexture, destination: nil)
            }
            #endif
        }
    }

    func makeMetalFXTextures(device: MTLDevice, pixelFormat: MTLPixelFormat, size: SIMD2<Float>) throws {
        logger?.debug("makeMetalFXTextures - \(size) \(metalFXRate)")
        let downscaledSize = SIMD2<Int>(ceil(size / metalFXRate))

        let colorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: downscaledSize.x, height: downscaledSize.y, mipmapped: false)
        colorTextureDescriptor.storageMode = .private
        colorTextureDescriptor.usage = [.renderTarget, .shaderRead]
        let colorTexture = try device.makeTexture(descriptor: colorTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        colorTexture.label = "reduce-resolution-color-\(colorTexture.size.shortDescription)"
        self.colorTexture = colorTexture

        let upscaledTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: Int(ceil(size.x)), height: Int(ceil(size.y)), mipmapped: false)
        upscaledTextureDescriptor.storageMode = .private
        upscaledTextureDescriptor.usage = .renderTarget
        let upscaledTexture = try device.makeTexture(descriptor: upscaledTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        upscaledTexture.label = "reduce-resolution-upscaled-\(upscaledTexture.size.shortDescription)"
        self.upscaledTexture = upscaledTexture
    }
}

extension MTLSize {
    var shortDescription: String {
        depth == 1 ? "\(width)x\(height)" : "\(width)x\(height)x\(depth)"
    }
}
