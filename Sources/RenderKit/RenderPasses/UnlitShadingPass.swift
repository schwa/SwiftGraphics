@preconcurrency import Metal
import MetalSupport
import RenderKitShadersLegacy
import SwiftGraphicsSupport

// TODO: Rename
public struct UnlitMaterialX: MaterialProtocol {
    public var baseColorFactor: SIMD4<Float>
    public var baseColorTexture: MTLTexture?

    public init(baseColorFactor: SIMD4<Float> = .zero, baseColorTexture: MTLTexture? = nil) {
        self.baseColorFactor = baseColorFactor
        self.baseColorTexture = baseColorTexture
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.baseColorFactor == rhs.baseColorFactor
        && lhs.baseColorTexture === rhs.baseColorTexture
    }
}

public struct UnlitShadingPass: RenderPassProtocol {
    public struct State: RenderPassState {
        var renderPipelineState: MTLRenderPipelineState
        var depthStencilState: MTLDepthStencilState

        struct Bindings {
            var vertexBufferIndex: Int
            var vertexCameraIndex: Int
            var vertexModelsIndex: Int
            var fragmentMaterialsIndex: Int
            var fragmentTexturesIndex: Int
        }
        var bindings: Bindings
    }

    public var id: AnyHashable = "UnlitShadingPass"
    public var scene: SceneGraph

    public init(scene: SceneGraph) {
        self.scene = scene
    }

    public func setup(context: Context, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let device = context.device

        let library = context.library
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "unlitVertexShader")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "unlitFragmentShader")
        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .less, isDepthWriteEnabled: true)
        let depthStencilState = try context.device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(RenderKitError.generic("Could not create depth stencil state"))
        renderPipelineDescriptor.label = "\(type(of: self))"

        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(oneTrueVertexDescriptor)

        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
        guard let reflection else {
            fatalError("No reflection for render pipeline.")
        }
        let bindings = State.Bindings(
            vertexBufferIndex: try reflection.binding(for: "vertexBuffer.0", of: .vertex),
            vertexCameraIndex: try reflection.binding(for: "camera", of: .vertex),
            vertexModelsIndex: try reflection.binding(for: "models", of: .vertex),
            fragmentMaterialsIndex: try reflection.binding(for: "materials", of: .fragment),
            fragmentTexturesIndex: try reflection.binding(for: "textures", of: .fragment)
        )

        return State(renderPipelineState: renderPipelineState, depthStencilState: depthStencilState, bindings: bindings)
    }

    public func encode(context: Context, state: State, drawableSize: SIMD2<Float>, commandEncoder: any MTLRenderCommandEncoder) throws {
        let helper = try SceneGraphRenderHelper(scene: scene, drawableSize: drawableSize)
        let elements = helper.elements(material: UnlitMaterialX.self)
        commandEncoder.setDepthStencilState(state.depthStencilState)
        commandEncoder.setRenderPipelineState(state.renderPipelineState)
        let bindings = state.bindings
        for element in elements {
            guard let material = element.material else {
                fatalError()
            }
            commandEncoder.withDebugGroup("Node: \(element.node.id)") {
                commandEncoder.withDebugGroup("VertexShader") {
                    let cameraUniforms = CameraUniforms(projectionMatrix: helper.projectionMatrix)
                    commandEncoder.setVertexBytes(of: cameraUniforms, index: bindings.vertexCameraIndex)

                    let modelTransforms = ModelTransforms(modelViewMatrix: element.modelViewMatrix, modelNormalMatrix: element.modelNormalMatrix)
                    commandEncoder.setVertexBytes(of: modelTransforms, index: bindings.vertexModelsIndex)
                }

                commandEncoder.withDebugGroup("FragmentShader") {
                    let vertexBuffer = element.geometry.mesh.vertexBuffers[0]
                    commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: bindings.vertexBufferIndex)
                    if let texture = material.baseColorTexture {
                        commandEncoder.setFragmentBytes(of: UnlitMaterial(color: material.baseColorFactor, textureIndex: 0), index: bindings.fragmentMaterialsIndex)
                        commandEncoder.setFragmentTextures([texture], range: 0..<(bindings.fragmentTexturesIndex + 1))
                    }
                    else {
                        commandEncoder.setFragmentBytes(of: UnlitMaterial(color: material.baseColorFactor, textureIndex: -1), index: bindings.fragmentMaterialsIndex)
                    }
                }

                assert(element.geometry.mesh.vertexBuffers.count == 1)
                commandEncoder.draw(element.geometry.mesh)
            }
        }
    }
}
