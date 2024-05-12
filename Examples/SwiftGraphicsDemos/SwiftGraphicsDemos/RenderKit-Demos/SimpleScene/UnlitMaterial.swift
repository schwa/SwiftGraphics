import SwiftUI
import ModelIO
import Metal
import MetalKit
import SIMDSupport
import RenderKitShaders
import RenderKit
import Observation
import Everything

public struct UnlitMaterial: Material {
    public var label: String?
    public var baseColorFactor: SIMD4<Float> = .one
    public var baseColorTexture: Texture?
}

// MARK: -

class UnlitMaterialRenderJob: SceneRenderJob {
    struct Bindings {
        var vertexBufferIndex: Int = -1
        var vertexCameraIndex: Int = -1
        var vertexModelsIndex: Int = -1
        var fragmentMaterialsIndex: Int = -1
        var fragmentTexturesIndex: Int = -1
    }
    struct DrawState {
        var renderPipelineState: MTLRenderPipelineState
        var depthStencilState: MTLDepthStencilState
        var bindings: Bindings
    }

    var scene: SimpleScene
    var models: [Model]
    private var bucketedDrawStates: [AnyHashable: DrawState] = [:]
    var textureManager: TextureManager

    init(scene: SimpleScene, textureManager: TextureManager, models: [Model]) {
        self.scene = scene
        self.models = models
        self.textureManager = textureManager
    }

    func setup<Configuration: MetalConfiguration>(device: MTLDevice, configuration: inout Configuration) throws {
        let library = try! device.makeDefaultLibrary(bundle: .shadersBundle)
        bucketedDrawStates = try models.reduce(into: [:]) { partialResult, model in
            let key = Pair(model.mesh.id, model.mesh.vertexDescriptor.encodedDescription)
            guard partialResult[key] == nil else {
                return
            }

            let vertexFunction = library.makeFunction(name: "unlitVertexShader")!
            let fragmentFunction = library.makeFunction(name: "unlitFragmentShader")!

            let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
            renderPipelineDescriptor.label = Names.shared.hashed(hashable: key, pad: 4)
            renderPipelineDescriptor.vertexFunction = vertexFunction
            renderPipelineDescriptor.fragmentFunction = fragmentFunction
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat
            renderPipelineDescriptor.depthAttachmentPixelFormat = configuration.depthStencilPixelFormat

            let descriptor = model.mesh.vertexDescriptor
            renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(descriptor)
            let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.argumentInfo])

            var bindings = Bindings()
            resolveBindings(reflection: reflection!, bindable: &bindings, [
                (\.vertexBufferIndex, .vertex, "vertexBuffer.0"),
                (\.vertexCameraIndex, .vertex, "camera"),
                (\.vertexModelsIndex, .vertex, "models"),
                (\.fragmentMaterialsIndex, .fragment, "materials"),
            ])

            let depthStencilState = device.makeDepthStencilState(descriptor: MTLDepthStencilDescriptor(depthCompareFunction: .lessEqual, isDepthWriteEnabled: true))!
            let drawState = DrawState(renderPipelineState: renderPipelineState, depthStencilState: depthStencilState, bindings: bindings)
            partialResult[key] = drawState
        }
    }

    func encode(on encoder: MTLRenderCommandEncoder, size: CGSize) throws {
        guard !models.isEmpty else {
            return
        }

        let bucketedModels: [AnyHashable: [Model]] = models.reduce(into: [:]) { partialResult, model in
            let key = Pair(model.mesh.id, model.mesh.vertexDescriptor.encodedDescription)
            partialResult[key, default: []].append(model)
        }

        for (key, drawState) in bucketedDrawStates {
            try encoder.withDebugGroup("Instanced Models") {
                encoder.setRenderPipelineState(drawState.renderPipelineState)
                encoder.setDepthStencilState(drawState.depthStencilState)
                let cameraUniforms = CameraUniforms(projectionMatrix: scene.camera.projection.matrix(viewSize: SIMD2<Float>(size)))
                let inverseCameraMatrix = scene.camera.transform.matrix.inverse
                encoder.setVertexBytes(of: cameraUniforms, index: drawState.bindings.vertexCameraIndex)

                let models = bucketedModels[key]!

                try encoder.withDebugGroup("Instanced \(key)") {
                    let mesh = models.first!.mesh
                    encoder.setVertexBuffers(mesh)
                    let modelTransforms = models.map { model in
                        ModelTransforms(
                            modelViewMatrix: inverseCameraMatrix * model.transform.matrix,
                            modelNormalMatrix: simd_float3x3(truncating: model.transform.matrix.transpose.inverse)
                        )
                    }
                    encoder.setVertexBytes(of: modelTransforms, index: drawState.bindings.vertexModelsIndex)

                    // TODO: Move to setup.
                    // TODO: needs to be a set() not an array()
                    let textures: [MTLTexture?] = try models.compactMap { model in
                        guard let texture = (model.material as! UnlitMaterial).baseColorTexture else {
                            return nil
                        }
                        return try textureManager.texture(for: texture.resource, options: texture.options)
                    }
                    encoder.setFragmentTextures(textures.extended(with: nil, count: 128 - textures.count), range: 0..<textures.count)

                    let materials = models.enumerated().map { index, model in
                        let color = (model.material as! UnlitMaterial).baseColorFactor
                        return RenderKitShaders.UnlitMaterial(color: color, textureIndex: Int16(index))
                    }
                    encoder.setFragmentBytes(of: materials, index: drawState.bindings.fragmentMaterialsIndex)

                    encoder.setTriangleFillMode(.fill)
                    encoder.draw(mesh, instanceCount: models.count)
                }
            }
        }
    }
}
