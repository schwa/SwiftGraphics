import BaseSupport
import CoreGraphicsSupport
import Metal
import MetalKit
import MetalSupport
import RenderKit
import simd
import SIMDSupport
import SwiftUI
import MetalFX

@Observable
public class GaussianSplatViewModel {
    public var debugMode: Bool
    public var sortRate: Int

    public init(debugMode: Bool = false, sortRate: Int = 1) {
        self.debugMode = debugMode
        self.sortRate = sortRate
    }
}

public struct GaussianSplatRenderView: View {
    private var device: MTLDevice
    private var scene: SceneGraph

    @Environment(GaussianSplatViewModel.self)
    private var viewModel

    public init(device: MTLDevice, scene: SceneGraph) {
        self.device = device
        self.scene = scene
    }

    public var body: some View {
        RenderView(device: device, passes: passes)
            .toolbar {
                // TODO: this should not be here.
                Button("Screenshot") {
                    screenshot()
                }
            }
    }

    var passes: [any PassProtocol] {
        guard let splatsNode = scene.node(for: "splats"), let splats = splatsNode.content as? Splats else {
            return []
        }
        guard let cameraNode = scene.node(for: "camera") else {
            return []
        }
        let preCalcComputePass = GaussianSplatPreCalcComputePass(
            splats: splats,
            modelMatrix: simd_float3x3(truncating: splatsNode.transform.matrix),
            cameraPosition: cameraNode.transform.translation
        )
        let gaussianSplatSortComputePass = GaussianSplatBitonicSortComputePass(
            splats: splats,
            sortRate: viewModel.sortRate
        )
        //        let gaussianSplatRenderPass = GaussianSplatRenderPass(
        //            scene: scene,
        //            debugMode: viewModel.debugMode
        //        )
        let gaussianSplatRenderPass = GaussianSplatRenderPass(
            scene: scene,
            debugMode: false)
        return [
            preCalcComputePass,
            gaussianSplatSortComputePass,
            gaussianSplatRenderPass
        ]
    }

    func screenshot() {
        do {
            let width = 1600
            let height = 1200
            let pixelFormat = MTLPixelFormat.bgra8Unorm_srgb

            let outputTextureDescriptor = MTLTextureDescriptor()
            outputTextureDescriptor.pixelFormat = pixelFormat
            outputTextureDescriptor.storageMode = .private
            outputTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            outputTextureDescriptor.width = width * 2
            outputTextureDescriptor.height = height * 2

            let outputTexture = device.makeTexture(descriptor: outputTextureDescriptor)!
            outputTexture.label = "Upscaled Texture"
            print(outputTexture)

            var offscreenConfiguration = OffscreenRenderPassConfiguration()
            offscreenConfiguration.clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
            offscreenConfiguration.depthStencilPixelFormat = .depth32Float
            offscreenConfiguration.depthStencilStorageMode = .memoryless
            offscreenConfiguration.clearDepth = 1
            offscreenConfiguration.colorPixelFormat = pixelFormat

            let currentRenderPassDescriptor = MTLRenderPassDescriptor()

            let targetTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
            targetTextureDescriptor.storageMode = .shared
            targetTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            let targetTexture = try device.makeTexture(descriptor: targetTextureDescriptor).safelyUnwrap(MetalSupportError.resourceCreationFailure)
            targetTexture.label = "Target Texture"
            currentRenderPassDescriptor.colorAttachments[0].texture = targetTexture
            currentRenderPassDescriptor.colorAttachments[0].loadAction = .clear
            currentRenderPassDescriptor.colorAttachments[0].storeAction = .store
            currentRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)


            let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: width, height: height, mipmapped: false)
            depthTextureDescriptor.storageMode = .memoryless
            depthTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            let depthStencilTexture = try device.makeTexture(descriptor: depthTextureDescriptor).safelyUnwrap(MetalSupportError.resourceCreationFailure)
            depthStencilTexture.label = "Depth Texture"
            currentRenderPassDescriptor.depthAttachment.texture = depthStencilTexture
            currentRenderPassDescriptor.depthAttachment.loadAction = .clear
            currentRenderPassDescriptor.depthAttachment.storeAction = .store
            currentRenderPassDescriptor.depthAttachment.clearDepth = 1

            let spatialUpscalingPass = SpatialUpscalingPass(id: "SpatialUpscalingPass", inputTexture: Box(targetTexture), outputPixelFormat: pixelFormat, outputSize: CGSize(width: width * 2, height: height * 2))


            var offscreenRenderer = try OffscreenRenderer(device: device, size: CGSize(width: width, height: height), offscreenConfiguration: offscreenConfiguration, renderPassDescriptor: currentRenderPassDescriptor, passes: passes + [spatialUpscalingPass])
            try offscreenRenderer.configure()
            try offscreenRenderer.render()

            guard let targetTexture = offscreenRenderer.targetTexture else {
                fatalError()
            }
            guard let cgImage = targetTexture.cgImage() else {
                fatalError()
            }
            let url = URL(filePath: "/tmp/test.png")
            try cgImage.write(to: url)
            url.reveal()
        }
        catch {
            print(error)
        }
    }
}

struct SpatialUpscalingPass: GeneralPassProtocol {
    struct State: PassState {
        var outputTexture: MTLTexture
        var spatialScaler: MTLFXSpatialScaler
    }

    let id: AnyHashable

    let inputTexture: Box<MTLTexture>
    let outputPixelFormat: MTLPixelFormat
    let outputSize: CGSize

    func setup(device: MTLDevice) throws -> State {
        let outputTextureDescriptor = MTLTextureDescriptor()
        outputTextureDescriptor.pixelFormat = outputPixelFormat
        outputTextureDescriptor.width = Int(outputSize.width)
        outputTextureDescriptor.height = Int(outputSize.height)
        let outputTexture = device.makeTexture(descriptor: outputTextureDescriptor)!
        let spatialScalerDescriptor = MTLFXSpatialScalerDescriptor()
        spatialScalerDescriptor.inputWidth = inputTexture.content.width
        spatialScalerDescriptor.inputHeight = inputTexture.content.height
        spatialScalerDescriptor.outputWidth = outputTexture.width
        spatialScalerDescriptor.outputHeight = outputTexture.height
        spatialScalerDescriptor.colorTextureFormat = inputTexture.content.pixelFormat
        spatialScalerDescriptor.outputTextureFormat = outputPixelFormat
        spatialScalerDescriptor.colorProcessingMode = .perceptual
        let spatialScaler = spatialScalerDescriptor.makeSpatialScaler(device: device)!
        spatialScaler.colorTexture = inputTexture.content
        spatialScaler.outputTexture = outputTexture
        return State(outputTexture: outputTexture, spatialScaler: spatialScaler)
    }

    func encode(device: MTLDevice, state: inout State, commandBuffer: MTLCommandBuffer) throws {
        state.spatialScaler.encode(commandBuffer: commandBuffer)
    }
}
