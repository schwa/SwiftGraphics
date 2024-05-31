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

struct PanoramaRenderPass: RenderPassProtocol {
    var id: AnyHashable = "PanoramaRenderPass"

    struct State: RenderPassState {
        var renderPipelineState: MTLRenderPipelineState
        var depthStencilState: MTLDepthStencilState
        var mesh: YAMesh
        var textures: [MTLTexture]
        var size: CGSize?
    }

    var scene: SimpleScene
    var panorama: Panorama
    var textureManager: TextureManager

    // TODO: WORKAROUND
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }

    init(scene: SimpleScene, textureManager: TextureManager, panorama: Panorama) {
        self.scene = scene
        self.textureManager = textureManager
        self.panorama = panorama
    }

    func setup(context: Context) throws -> State {
        let device = context.device
        let library = try! device.makeDefaultLibrary(bundle: .renderKitShaders)
        let vertexFunction = library.makeFunction(name: "panoramicVertexShader")!
        let constantValues = MTLFunctionConstantValues()
        let fragmentFunction = try library.makeFunction(name: "panoramicFragmentShader", constantValues: constantValues)
        let depthStencilState = device.makeDepthStencilState(descriptor: MTLDepthStencilDescriptor.always())!
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = context.depthAttachmentPixelFormat
        let descriptor = VertexDescriptor.packed(semantics: [.position, .normal, .textureCoordinate])
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(descriptor)
        let renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        let mesh = try! panorama.mesh(device)
        let loader = MTKTextureLoader(device: device)
        let textures = try panorama.tileTextures.map { try $0(loader) }

        return .init(renderPipelineState: renderPipelineState, depthStencilState: depthStencilState, mesh: mesh, textures: textures)
    }

    func sizeWillChange(context: Context, state: inout State, size: CGSize) throws {
        state.size = size
    }

    func encode(context: Context, state: State, commandEncoder: MTLRenderCommandEncoder) throws {
        let device = context.device
        guard let size = state.size else {
            return
        }
        commandEncoder.withDebugGroup("Panorama") {
            commandEncoder.setRenderPipelineState(state.renderPipelineState)
            commandEncoder.setDepthStencilState(state.depthStencilState)
            commandEncoder.setVertexBuffers(state.mesh)
            let cameraUniforms = CameraUniforms(projectionMatrix: scene.camera.projection.matrix(viewSize: SIMD2<Float>(size)))
            let inverseCameraMatrix = scene.camera.transform.matrix.inverse
            commandEncoder.setVertexBytes(of: cameraUniforms, index: 1)
            let modelViewMatrix = inverseCameraMatrix * float4x4.translation(scene.camera.transform.translation)
            commandEncoder.setVertexBytes(of: modelViewMatrix, index: 2)
            let uniforms = PanoramaFragmentUniforms(gridSize: panorama.tilesSize, colorFactor: [1, 1, 1, 1])
            commandEncoder.setFragmentBytes(of: uniforms, index: 0)
            commandEncoder.setFragmentTextures(state.textures, range: 0 ..< state.textures.count)
            // commandEncoder.setTriangleFillMode(.fill)
            commandEncoder.draw(state.mesh)
        }
    }
}
