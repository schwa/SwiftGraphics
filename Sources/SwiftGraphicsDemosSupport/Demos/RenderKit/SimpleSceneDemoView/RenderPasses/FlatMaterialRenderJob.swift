import Metal
import MetalKit
import MetalUISupport
import ModelIO
import Observation
import RenderKit4
import RenderKitShaders
import SIMDSupport
import SwiftUI

struct FlatMaterial: Material {
    var label: String?
    var baseColorFactor: SIMD4<Float> = .one
    var baseColorTexture: Texture?
}

@available(*, deprecated, message: "Deprecated")
class FlatMaterialRenderJob: SceneRenderJob {
    struct Bindings {
        var vertexBufferIndex: Int = -1
        var vertexCameraIndex: Int = -1
        var vertexModelTransformsIndex: Int = -1
        var fragmentLightingIndex: Int = -1
        var fragmentMaterialsIndex: Int = -1
    }

    struct DrawState {
        var renderPipelineState: MTLRenderPipelineState
        var depthStencilState: MTLDepthStencilState
        var bindings: Bindings
    }

    var models: [Model]
    var scene: SimpleScene
    private var bucketedDrawStates: [AnyHashable: DrawState] = [:]
    var textureManager: TextureManager // TODO: move to "parent"

    init(scene: SimpleScene, textureManager: TextureManager, models: [Model]) {
        self.scene = scene
        self.models = models
        self.textureManager = textureManager
    }

    func setup(device: MTLDevice, configuration: inout some MetalConfiguration) throws {
        let library = try! device.makeDefaultLibrary(bundle: .renderKitShaders)
        bucketedDrawStates = try models.reduce(into: [:]) { partialResult, model in
            let key = Pair(model.mesh.id, model.mesh.vertexDescriptor.encodedDescription)
            guard partialResult[key] == nil else {
                return
            }
            let vertexFunction = library.makeFunction(name: "flatShaderVertexShader")!
            let fragmentFunction = library.makeFunction(name: "flatShaderFragmentShader")!
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
                (\.vertexModelTransformsIndex, .vertex, "modelTransforms"),
                (\.fragmentLightingIndex, .fragment, "lighting"),
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
                let lightUniforms = LightUniforms(lightPosition: scene.light.position.translation, lightColor: scene.light.color, lightPower: scene.light.power, ambientLightColor: scene.ambientLightColor)
                encoder.setFragmentBytes(of: lightUniforms, index: drawState.bindings.fragmentLightingIndex)

                let models = bucketedModels[key]!

                // TODO: Move to setup.
                // TODO: needs to be a set() not an array()
                let textures: [MTLTexture] = try models.compactMap { model in
                    guard let texture = (model.material as! FlatMaterial).baseColorTexture else {
                        return nil
                    }
                    return try textureManager.texture(for: texture.resource, options: texture.options)
                }
                encoder.setFragmentTextures(textures, range: 0 ..< textures.count)

                let materials = models.enumerated().map { _, model in
                    let color = (model.material as! FlatMaterial).baseColorFactor
                    return RenderKitShaders.FlatMaterial(diffuseColor: color, diffuseTextureIndex: -1, ambientColor: color, ambientTextureIndex: -1)
                }
                encoder.setFragmentBytes(of: materials, index: drawState.bindings.fragmentMaterialsIndex)

                encoder.withDebugGroup("Instanced \(key)") {
                    let mesh = models.first!.mesh
                    encoder.setVertexBuffers(mesh)
                    let modelTransforms = models.map { model in
                        ModelTransforms(
                            modelViewMatrix: inverseCameraMatrix * model.transform.matrix,
                            modelNormalMatrix: simd_float3x3(truncating: model.transform.matrix.transpose.inverse)
                        )
                    }
                    encoder.setVertexBytes(of: modelTransforms, index: drawState.bindings.vertexModelTransformsIndex)
                    encoder.setTriangleFillMode(.fill)
                    encoder.draw(mesh, instanceCount: models.count)
                }
            }
        }
    }
}
