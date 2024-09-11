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
import Shapes3D

@Observable
@MainActor
public class GaussianSplatViewModel <Splat> where Splat: SplatProtocol {
    public var scene: SceneGraph {
        didSet {
            try! updatePass()
        }
    }

    public var pass: GroupPass?

    @ObservationIgnored
    public let device: MTLDevice

    @ObservationIgnored
    public var configuration: GaussianSplatRenderingConfiguration

    @ObservationIgnored
    var resources: GaussianSplatResources?

    @ObservationIgnored
    public var frame: Int = 0 {
        didSet {
            try! updatePass()
        }
    }

    @ObservationIgnored
    public var logger: Logger?

    public init(device: MTLDevice, splatCloud: SplatCloud<SplatC>, configuration: GaussianSplatRenderingConfiguration = .init(), logger: Logger? = nil) throws {
        self.device = device
        self.configuration = configuration
        self.logger = logger

        let panoramaMesh = try Box3D(min: [-400, -400, -400], max: [400, 400, 400]).toMTKMesh(device: device, inwardNormals: true)
        let loader = MTKTextureLoader(device: device)
        let panoramaTexture = try loader.newTexture(name: "Grid", scaleFactor: 2, bundle: Bundle.module)
        let root = Node(label: "root") {
            Node(label: "camera", content: Camera())
            Node(label: "pano", content: Geometry(mesh: panoramaMesh, materials: [PanoramaMaterial(baseColorTexture: panoramaTexture)]))
            Node(label: "splats", content: splatCloud).transformed(roll: .zero, pitch: .degrees(270), yaw: .zero).transformed(roll: .zero, pitch: .zero, yaw: .degrees(90)).transformed(translation: [0, 0.25, 0.5])
        }
        self.scene = SceneGraph(root: root)



        try updatePass()
    }

    func updatePass() throws {
        guard let resources else {
            logger?.log("Missing resources")
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

        let fullRedraw = true
        let sortEnabled = configuration.sortRate <= 1 || (frame <= 1 || frame.isMultiple(of: configuration.sortRate))

        self.pass = try GroupPass(id: "FullPass") {
            GroupPass(id: "GaussianSplatRenderGroup", enabled: fullRedraw, renderPassDescriptor: offscreenRenderPassDescriptor) {
                GaussianSplatDistanceComputePass(
                    id: "SplatDistanceCompute",
                    enabled: sortEnabled,
                    splats: splats,
                    modelMatrix: simd_float3x3(truncating: splatsNode.transform.matrix),
                    cameraPosition: cameraNode.transform.translation
                )
                GaussianSplatBitonicSortComputePass(
                    id: "SplatBitonicSort",
                    enabled: sortEnabled,
                    splats: splats
                )
                PanoramaShadingPass(id: "Panorama", scene: scene)
                GaussianSplatRenderPass<Splat>(
                    id: "SplatRender",
                    enabled: true,
                    scene: scene,
                    discardRate: configuration.discardRate
                )
            }
            #if !targetEnvironment(simulator)
            try SpatialUpscalingPass(id: "SpatialUpscalingPass", enabled: configuration.metalFXRate > 1 && fullRedraw, device: device, source: resources.downscaledTexture, destination: resources.outputTexture, colorProcessingMode: .perceptual)
            #endif
            BlitTexturePass(id: "BlitTexturePass", source: resources.outputTexture, destination: nil)
        }
    }

    func makeResources(pixelFormat: MTLPixelFormat, size: SIMD2<Float>) throws {
        logger?.debug("makeMetalFXTextures - \(size) \(self.configuration.metalFXRate)")
        let downscaledSize = SIMD2<Int>(ceil(size / configuration.metalFXRate))

        let colorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: downscaledSize.x, height: downscaledSize.y, mipmapped: false)
        colorTextureDescriptor.storageMode = .private
        colorTextureDescriptor.usage = [.renderTarget, .shaderRead]
        let colorTexture = try device.makeTexture(descriptor: colorTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        colorTexture.label = "reduce-resolution-color-\(colorTexture.size.shortDescription)"

        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: downscaledSize.x, height: downscaledSize.y, mipmapped: false)
        depthTextureDescriptor.storageMode = .private
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead]
        let depthTexture = try device.makeTexture(descriptor: depthTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        depthTexture.label = "reduce-resolution-depth-\(depthTexture.size.shortDescription)"

        let upscaledTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: Int(ceil(size.x)), height: Int(ceil(size.y)), mipmapped: false)
        upscaledTextureDescriptor.storageMode = .private
        upscaledTextureDescriptor.usage = .renderTarget
        let upscaledTexture = try device.makeTexture(descriptor: upscaledTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        upscaledTexture.label = "reduce-resolution-upscaled-\(upscaledTexture.size.shortDescription)"

        self.resources = .init(downscaledTexture: colorTexture, downscaledDepthTexture: depthTexture, outputTexture: upscaledTexture)
    }

    var offscreenRenderPassDescriptor: MTLRenderPassDescriptor {
        guard let resources else {
            fatalError("Tried to create renderpass without resources.")
        }
        let offscreenRenderPassDescriptor = MTLRenderPassDescriptor()
        offscreenRenderPassDescriptor.colorAttachments[0].clearColor = configuration.clearColor
        offscreenRenderPassDescriptor.colorAttachments[0].texture = configuration.metalFXRate <= 1 ? resources.outputTexture : resources.downscaledTexture
        offscreenRenderPassDescriptor.colorAttachments[0].loadAction = .load
        offscreenRenderPassDescriptor.colorAttachments[0].storeAction = .store
        offscreenRenderPassDescriptor.depthAttachment.loadAction = .clear
        offscreenRenderPassDescriptor.depthAttachment.storeAction = .dontCare
        offscreenRenderPassDescriptor.depthAttachment.clearDepth = 1.0
        offscreenRenderPassDescriptor.depthAttachment.texture = resources.downscaledDepthTexture
        return offscreenRenderPassDescriptor
    }
}


struct GaussianSplatResources {
    var downscaledTexture: MTLTexture
    var downscaledDepthTexture: MTLTexture
    var outputTexture: MTLTexture
}


extension MTLSize {
    var shortDescription: String {
        depth == 1 ? "\(width)x\(height)" : "\(width)x\(height)x\(depth)"
    }
}
