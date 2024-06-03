import Metal
import MetalKit
import MetalSupport
import MetalUISupport
import ModelIO
import Observation
import RenderKit
import RenderKit4
import RenderKitShaders
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI

@available(*, deprecated, message: "Deprecated")
class PanoramaRenderJob: SceneRenderJob {
    var renderPipelineState: MTLRenderPipelineState?
    var depthStencilState: MTLDepthStencilState?
    var mesh: YAMesh?

    var scene: SimpleScene
    var panorama: Panorama
    var textureManager: TextureManager
    var textures: [MTLTexture] = []

    init(scene: SimpleScene, textureManager: TextureManager, panorama: Panorama) {
        self.scene = scene
        self.textureManager = textureManager
        self.panorama = panorama
    }

    func setup(device: MTLDevice, configuration: inout some MetalConfiguration) throws {
        let library = try! device.makeDefaultLibrary(bundle: .renderKitShaders)
        let vertexFunction = library.makeFunction(name: "panoramicVertexShader")!
        let constantValues = MTLFunctionConstantValues()
        let fragmentFunction = try library.makeFunction(name: "panoramicFragmentShader", constantValues: constantValues)
        depthStencilState = device.makeDepthStencilState(descriptor: MTLDepthStencilDescriptor.always())
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = configuration.depthStencilPixelFormat
        let descriptor = VertexDescriptor.packed(semantics: [.position, .normal, .textureCoordinate])
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(descriptor)
        renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        mesh = try! panorama.mesh(device)
        let loader = MTKTextureLoader(device: device)
        textures = try panorama.tileTextures.map { try $0(loader) }
    }

    func encode(on encoder: MTLRenderCommandEncoder, size: CGSize) throws {
        guard let renderPipelineState, let depthStencilState else {
            return
        }
        encoder.withDebugGroup("Panorama") {
            guard let mesh else {
                fatalError("No mesh")
            }
            encoder.setRenderPipelineState(renderPipelineState)
            encoder.setDepthStencilState(depthStencilState)
            encoder.setVertexBuffers(mesh)
            let cameraUniforms = CameraUniforms(projectionMatrix: scene.camera.projection.matrix(viewSize: SIMD2<Float>(size)))
            let inverseCameraMatrix = scene.camera.transform.matrix.inverse
            encoder.setVertexBytes(of: cameraUniforms, index: 1)
            let modelViewMatrix = inverseCameraMatrix * float4x4.translation(scene.camera.transform.translation)
            encoder.setVertexBytes(of: modelViewMatrix, index: 2)
            let uniforms = PanoramaFragmentUniforms(gridSize: panorama.tilesSize, colorFactor: [1, 1, 1, 1])
            encoder.setFragmentBytes(of: uniforms, index: 0)
            encoder.setFragmentTextures(textures, range: 0 ..< textures.count)
            // encoder.setTriangleFillMode(.fill)
            encoder.draw(mesh)
        }
    }
}