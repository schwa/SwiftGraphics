import BaseSupport
@preconcurrency import Metal
import MetalSupport
import ModelIO
import RenderKit
import RenderKitShaders

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
    public struct State: PassState {
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

    public var id: PassID
    public var scene: SceneGraph

    public init(id: PassID, scene: SceneGraph) {
        self.id = id
        self.scene = scene
    }

    public func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .renderKitShaders)
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "unlitVertexShader")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "unlitFragmentShader")
        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .less, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        renderPipelineDescriptor.label = "\(type(of: self))"

        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(MDLVertexDescriptor.simpleVertexDescriptor)

        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
        guard let reflection else {
            throw BaseError.resourceCreationFailure
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

    public func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, state: State) throws {
        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "\(type(of: self))") { commandEncoder in
            try commandEncoder.withDebugGroup("Start encoding for \(type(of: self))") {
                let helper = try SceneGraphRenderHelper(scene: scene, targetColorAttachment: renderPassDescriptor.colorAttachments[0])
                let elements = helper.elements()
                commandEncoder.setDepthStencilState(state.depthStencilState)
                commandEncoder.setRenderPipelineState(state.renderPipelineState)
                let bindings = state.bindings
                for element in elements {
                    guard let geometry = element.node.geometry, let material = geometry.materials.compactMap({ $0 as? UnlitMaterialX }).first else {
                        continue
                    }
                    commandEncoder.withDebugGroup("Node: \(element.node.id)") {
                        commandEncoder.withDebugGroup("VertexShader") {
                            let cameraUniforms = CameraUniformsNEW(viewMatrix: helper.viewMatrix, projectionMatrix: helper.projectionMatrix)
                            commandEncoder.setVertexBytes(of: cameraUniforms, index: bindings.vertexCameraIndex)

                            let modelTransforms = ModelTransformsNEW(modelViewMatrix: element.modelViewMatrix, modelNormalMatrix: element.modelNormalMatrix)
                            commandEncoder.setVertexBytes(of: modelTransforms, index: bindings.vertexModelsIndex)
                        }

                        commandEncoder.withDebugGroup("FragmentShader") {
                            let vertexBuffer = geometry.mesh.vertexBuffers[0]
                            commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: bindings.vertexBufferIndex)
                            if let texture = material.baseColorTexture {
                                commandEncoder.setFragmentBytes(of: UnlitMaterial(color: material.baseColorFactor, textureIndex: 0), index: bindings.fragmentMaterialsIndex)
                                commandEncoder.setFragmentTextures([texture], range: 0..<(bindings.fragmentTexturesIndex + 1))
                            } else {
                                commandEncoder.setFragmentBytes(of: UnlitMaterial(color: material.baseColorFactor, textureIndex: -1), index: bindings.fragmentMaterialsIndex)
                            }
                        }

                        assert(geometry.mesh.vertexBuffers.count == 1)
                        commandEncoder.draw(geometry.mesh)
                    }
                }
            }
        }
    }
}
