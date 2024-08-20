import BaseSupport
import Metal
#if !targetEnvironment(simulator)
import MetalFX
#endif
import MetalKit
import MetalSupport
import os
import RenderKit
import RenderKitSceneGraph
import simd
import SIMDSupport
import SwiftUI
import SwiftUISupport

public struct GaussianSplatRenderView <Splat>: View where Splat: SplatProtocol {
    @Environment(\.metalDevice)
    var device

    @Environment(\.logger)
    var logger

    @State
    private var drawableSize: SIMD2<Float> = .zero

    @Environment(GaussianSplatViewModel<Splat>.self)
    var viewModel

    public init() {
    }

    public var body: some View {
        // swiftlint:disable:next force_try
        RenderView(pass: viewModel.pass) { configuration in
            configuration.colorPixelFormat = .bgra8Unorm_srgb
            configuration.depthStencilPixelFormat = .invalid
            configuration.framebufferOnly = false
        }
        sizeWillChange: { _, configuration, size in
            do {
                let size = SIMD2<Float>(size)
                guard drawableSize != size else {
                    return
                }
                drawableSize = SIMD2<Float>(size)
                logger?.debug("\(type(of: self)).\(#function): \(drawableSize)")
                try viewModel.makeTextures(pixelFormat: configuration.colorPixelFormat, size: drawableSize)
            } catch {
                fatalError("Failed to create texture.")
            }
        }
        didDraw: {
            viewModel.frame += 1
        }
        .onChange(of: viewModel.metalFXRate) {
            do {
                try viewModel.makeTextures(pixelFormat: .bgra8Unorm_srgb, size: drawableSize)
            } catch {
                logger?.error("Failed to make metal textures: \(error)")
            }
        }
    }
}

@Observable
@MainActor
public class GaussianSplatViewModel <Splat> where Splat: SplatProtocol {
    public var scene: SceneGraph {
        didSet {
            try! updatePass()
        }
    }
    @ObservationIgnored
    public var lastScene: SceneGraph?
    @ObservationIgnored
    public let device: MTLDevice
    @ObservationIgnored
    public let debugMode: Bool
    @ObservationIgnored
    public let sortRate: Int
    @ObservationIgnored
    public let metalFXRate: Float
    @ObservationIgnored
    public let gpuCounters: GPUCounters?
    @ObservationIgnored
    public let discardRate: Float
    @ObservationIgnored
    public var logger: Logger?

    @ObservationIgnored
    private var downscaledTexture: MTLTexture? {
        didSet {
            try! updatePass()
        }
    }

    @ObservationIgnored
    private var outputTexture: MTLTexture? {
        didSet {
            try! updatePass()
        }
    }
    public var pass: GroupPass?

    @ObservationIgnored
    public var frame: Int = 0 {
        didSet {
            try! updatePass()
        }
    }

    public init(device: MTLDevice, scene: SceneGraph, debugMode: Bool = false, sortRate: Int = 1, metalFXRate: Float = 1, gpuCounters: GPUCounters? = nil, discardRate: Float = 0, logger: Logger? = nil) throws {
        self.device = device
        self.scene = scene
        self.debugMode = debugMode
        self.sortRate = sortRate
        self.metalFXRate = metalFXRate
        self.gpuCounters = gpuCounters
        self.discardRate = discardRate
        self.logger = logger

        try updatePass()
    }

    func updatePass() throws {
        guard let downscaledTexture, let outputTexture else {
            logger?.log("Missing texture")
            return
        }
        guard let splatsNode = scene.firstNode(label: "splats"), let splats = splatsNode.content as? SplatCloud<Splat> else {
            logger?.log("Missing splats")
            return
        }
        guard let cameraNode = scene.firstNode(label: "camera") else {
            logger?.log("Missing camera")
            return
        }

//        let sceneChanged = scene != lastScene
        lastScene = scene
        let sceneChanged = true

        logger?.log("Scene changed? \(sceneChanged). metalFXRate: \(self.metalFXRate). sortRate: \(self.sortRate)")

        let offscreenRenderPassDescriptor = MTLRenderPassDescriptor()
        offscreenRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        offscreenRenderPassDescriptor.colorAttachments[0].texture = metalFXRate <= 1 ? outputTexture : downscaledTexture
        offscreenRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        offscreenRenderPassDescriptor.colorAttachments[0].storeAction = .store

        self.pass = try GroupPass(id: "FullPass") {
            GroupPass(id: "GaussianSplatRenderGroup", enabled: sceneChanged, renderPassDescriptor: offscreenRenderPassDescriptor) {
                GaussianSplatDistanceComputePass(
                    id: "SplatDistanceCompute",
                    enabled: true,
                    splats: splats,
                    modelMatrix: simd_float3x3(truncating: splatsNode.transform.matrix),
                    cameraPosition: cameraNode.transform.translation,
                    sortRate: sortRate
                )
                GaussianSplatBitonicSortComputePass(
                    id: "SplatBitonicSort",
                    enabled: true,
                    splats: splats,
                    sortRate: sortRate
                )
                GaussianSplatRenderPass<Splat>(
                    id: "SplatRender",
                    enabled: true,
                    scene: scene,
                    discardRate: discardRate
                )
            }
            #if !targetEnvironment(simulator)
            try SpatialUpscalingPass(id: "SpatialUpscalingPass", enabled: metalFXRate > 1 && sceneChanged, device: device, source: downscaledTexture, destination: outputTexture, colorProcessingMode: .perceptual)
            #endif
            BlitTexturePass(id: "BlitTexturePass", source: outputTexture, destination: nil)
        }
    }

    func makeTextures(pixelFormat: MTLPixelFormat, size: SIMD2<Float>) throws {
        logger?.debug("makeMetalFXTextures - \(size) \(self.metalFXRate)")
        let downscaledSize = SIMD2<Int>(ceil(size / metalFXRate))

        let colorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: downscaledSize.x, height: downscaledSize.y, mipmapped: false)
        colorTextureDescriptor.storageMode = .private
        colorTextureDescriptor.usage = [.renderTarget, .shaderRead]
        let colorTexture = try device.makeTexture(descriptor: colorTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        colorTexture.label = "reduce-resolution-color-\(colorTexture.size.shortDescription)"
        self.downscaledTexture = colorTexture

        let upscaledTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: Int(ceil(size.x)), height: Int(ceil(size.y)), mipmapped: false)
        upscaledTextureDescriptor.storageMode = .private
        upscaledTextureDescriptor.usage = .renderTarget
        let upscaledTexture = try device.makeTexture(descriptor: upscaledTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        upscaledTexture.label = "reduce-resolution-upscaled-\(upscaledTexture.size.shortDescription)"
        self.outputTexture = upscaledTexture
    }
}

extension MTLSize {
    var shortDescription: String {
        depth == 1 ? "\(width)x\(height)" : "\(width)x\(height)x\(depth)"
    }
}

extension SceneGraph {
    func hasChanged(from other: SceneGraph) -> Bool {
        self.root.generationID != other.root.generationID
    }
}
