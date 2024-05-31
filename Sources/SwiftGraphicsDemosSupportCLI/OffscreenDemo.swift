import MetalKit
import MetalSupport
import ModelIO
import simd
import SIMDSupport
import SwiftUI

public class OffscreenRenderPass: RenderPass {
    public typealias Configuration = OffscreenRenderPassConfiguration
    public var shaderToyRenderPipelineState: MTLRenderPipelineState?
    public var plane: MTKMesh?
    public var pixelate = false
    public var scale = SIMD2<Float>(16, 16)
    public var speed = Float(1)
    public var time = Float(0)
    public var texture: MTLTexture?
    public var sampler: MTLSamplerState?
    public var capture = false

    public init() {
    }

    public func setup(device: MTLDevice, configuration: inout some MetalConfiguration) throws {
        let library = try! device.makeDefaultLibrary(bundle: .shadersBundle)
        let constants = MTLFunctionConstantValues()

        let textureLoader = MTKTextureLoader(device: device)
        texture = try! textureLoader.newTexture(name: "HD-Testcard-original", scaleFactor: 1.0, bundle: .main)

        let samplerDescriptor = MTLSamplerDescriptor()
        sampler = device.makeSamplerState(descriptor: samplerDescriptor)

        let vertexFunction = try! library.makeFunction(name: "demoBlitVertexShader", constantValues: constants)
        let fragmentFunction = try! library.makeFunction(name: "demoBlitFragmentShader", constantValues: constants)
        let plane = try! MTKMesh(mesh: Plane(extent: [2, 2, 0]).toMDLMesh(allocator: MTKMeshBufferAllocator(device: device)), device: device)
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = configuration.depthStencilPixelFormat
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(plane.vertexDescriptor)
        let shaderToyRenderPipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        self.plane = plane
        self.shaderToyRenderPipelineState = shaderToyRenderPipelineState
    }

    public func draw(device: MTLDevice, size: CGSize, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) throws {
        guard let plane, let shaderToyRenderPipelineState else {
            return
        }
        var captureScope: MTLCaptureScope?
        if capture {
            let captureManager = MTLCaptureManager.shared()
            captureScope = captureManager.makeCaptureScope(device: device)
            let captureDescriptor = MTLCaptureDescriptor()
            captureDescriptor.captureObject = captureScope
            try! captureManager.startCapture(with: captureDescriptor)
            captureScope?.begin()
        }
        commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor) { encoder in
            encoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(size.width), height: Double(size.height), znear: 0, zfar: 1))
            encoder.setCullMode(.back)
            encoder.setRenderPipelineState(shaderToyRenderPipelineState)
            //
            encoder.setVertexBytes(of: simd_float4x3.identity, index: 1)
            //

            encoder.setFragmentTexture(texture, index: 0)
            encoder.setFragmentSamplerState(sampler, index: 0)

            //
//            encoder.draw(plane)
        }

        captureScope?.end()
    }
}

#if os(macOS)
    public enum OffscreenDemo {
        public static func main() async throws {
            let device = MTLCreateSystemDefaultDevice()!
            var configuration = OffscreenRenderPassConfiguration(device: device, size: [1_024, 769])
            configuration.colorPixelFormat = .bgra10_xr_srgb
            configuration.update()
            let offscreen = OffscreenRenderPass()
            try offscreen.setup(device: device, configuration: &configuration)

            guard let commandQueue = device.makeCommandQueue() else {
                fatalError()
            }
            try commandQueue.withCommandBuffer(waitAfterCommit: true) { commandBuffer in
                try offscreen.draw(device: device, size: configuration.size, renderPassDescriptor: configuration.currentRenderPassDescriptor!, commandBuffer: commandBuffer)
            }

//        let histogram = configuration.targetTexture!.histogram()
//        histogram.withEx(type: UInt32.self, count: 4 * 256) { pointer in
//        }
            let image = await configuration.targetTexture!.cgImage(colorSpace: CGColorSpace(name: CGColorSpace.displayP3))
            let url = URL(filePath: "/tmp/test.jpg")
            try image.write(to: URL(filePath: "/tmp/test.jpg"))
            let openConfiguration = NSWorkspace.OpenConfiguration()
            openConfiguration.activates = true
            _ = try await NSWorkspace.shared.open(url, configuration: openConfiguration)
        }
    }
#endif
