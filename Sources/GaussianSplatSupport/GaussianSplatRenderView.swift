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
        [GaussianSplatCompositePass(id: "GaussianSplatCompositePass", scene: scene, sortRate: viewModel.sortRate)]
    }

    func screenshot() {
        do {
            let width = 640
            let height = 480
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

            let upscaledPrivateTextureDescriptor = MTLTextureDescriptor()
            upscaledPrivateTextureDescriptor.pixelFormat = pixelFormat
            upscaledPrivateTextureDescriptor.width = width * 2
            upscaledPrivateTextureDescriptor.height = height * 2
            upscaledPrivateTextureDescriptor.storageMode = .private
            upscaledPrivateTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            let upscaledPrivateTexture = try device.makeTexture(descriptor: upscaledPrivateTextureDescriptor).safelyUnwrap(BaseError.generic("OOPS"))
            let spatialUpscalingPass = SpatialUpscalingPass(id: "SpatialUpscalingPass", inputTexture: targetTexture, outputTexture: upscaledPrivateTexture, colorProcessingMode: .perceptual)

            let upscaledSharedTextureDescriptor = upscaledPrivateTextureDescriptor
            upscaledSharedTextureDescriptor.storageMode = .shared
            let upscaledSharedTexture = try device.makeTexture(descriptor: upscaledSharedTextureDescriptor).safelyUnwrap(BaseError.generic("OOPS"))

            let blitPass = BlitTexturePass(id: "BlitTexturePass", source: upscaledPrivateTexture, destination: upscaledSharedTexture)

            let passes = passes + [spatialUpscalingPass, blitPass]

            var offscreenRenderer = try OffscreenRenderer(device: device, size: CGSize(width: width, height: height), offscreenConfiguration: offscreenConfiguration, renderPassDescriptor: renderPassDescriptor, passes: passes + [spatialUpscalingPass])
            try offscreenRenderer.configure()
            try offscreenRenderer.render()

            try targetTexture.cgImage().write(to: URL(filePath: "/tmp/test.png"))
            try upscaledSharedTexture.cgImage().write(to: URL(filePath: "/tmp/test-upscaled.png"))
            URL(filePath: "/tmp/test.png").reveal()
        }
        catch {
            print(error)
        }
    }
}

// MARK: -

struct BlitTexturePass: GeneralPassProtocol {
    let id: AnyHashable

    struct State: PassState {
    }

    let source: Box<MTLTexture>
    let destination: Box<MTLTexture>

    init(id: AnyHashable, source: MTLTexture, destination: MTLTexture) {
        self.id = id
        self.source = Box(source)
        self.destination = Box(destination)
    }

    func setup(device: MTLDevice) throws -> (State) {
        State()
    }

    func encode(device: MTLDevice, state: inout State, commandBuffer: MTLCommandBuffer) throws {
        let blitCommandEncoder = try commandBuffer.makeBlitCommandEncoder().safelyUnwrap(BaseError.generic("TODO")) // TODO: Sanitize error types.
        blitCommandEncoder.label = "BlitTexturePass(\(id))"
        blitCommandEncoder.copy(from: source(), to: destination())
        blitCommandEncoder.endEncoding()
    }
}

// MARK: -

struct SpatialUpscalingPass: GeneralPassProtocol {
    struct State: PassState {
        var spatialScaler: MTLFXSpatialScaler
    }

    var id: AnyHashable
    var inputTexture: Box<MTLTexture>
    var outputTexture: Box<MTLTexture>
    var colorProcessingMode: MTLFXSpatialScalerColorProcessingMode

    init(id: AnyHashable, inputTexture: MTLTexture, outputTexture: MTLTexture, colorProcessingMode: MTLFXSpatialScalerColorProcessingMode) {
        self.id = id
        self.inputTexture = Box(inputTexture)
        self.outputTexture = Box(outputTexture)
        self.colorProcessingMode = colorProcessingMode
    }

    func setup(device: MTLDevice) throws -> State {
        let spatialScalerDescriptor = MTLFXSpatialScalerDescriptor()
        spatialScalerDescriptor.inputWidth = inputTexture().width
        spatialScalerDescriptor.inputHeight = inputTexture().height
        spatialScalerDescriptor.outputWidth = outputTexture().width
        spatialScalerDescriptor.outputHeight = outputTexture().height
        spatialScalerDescriptor.colorTextureFormat = inputTexture().pixelFormat
        spatialScalerDescriptor.outputTextureFormat = outputTexture().pixelFormat
        spatialScalerDescriptor.colorProcessingMode = colorProcessingMode

        let spatialScaler = try spatialScalerDescriptor.makeSpatialScaler(device: device).safelyUnwrap(BaseError.generic("OOPS"))
        spatialScaler.colorTexture = inputTexture.content
        spatialScaler.outputTexture = outputTexture.content

        return State(spatialScaler: spatialScaler)
    }

    func encode(device: MTLDevice, state: inout State, commandBuffer: MTLCommandBuffer) throws {
        state.spatialScaler.encode(commandBuffer: commandBuffer)
    }
}

struct GaussianSplatCompositePass: CompositePassProtocol {
    var id: AnyHashable
    var scene: SceneGraph
    var sortRate: Int

    func children() throws -> [any PassProtocol] {
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
            sortRate: sortRate
        )
        let gaussianSplatRenderPass = GaussianSplatRenderPass(
            scene: scene,
            debugMode: false
        )
        return [
            preCalcComputePass,
            gaussianSplatSortComputePass,
            gaussianSplatRenderPass
        ]
    }
}
