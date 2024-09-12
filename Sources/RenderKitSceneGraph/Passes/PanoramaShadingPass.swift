import BaseSupport
@preconcurrency import Metal
import MetalSupport
import ModelIO
import RenderKit
import RenderKitShaders

public struct PanoramaMaterial: MaterialProtocol {
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

public struct PanoramaShadingPass: RenderPassProtocol {
    public struct State: Sendable {
        var renderPipelineState: MTLRenderPipelineState
        var depthStencilState: MTLDepthStencilState

        @MetalBindings
        struct Bindings {
            @MetalBinding(name: "camera", function: .vertex)
            var vertexCameraIndex: Int = -1
            @MetalBinding(name: "models", function: .vertex)
            var vertexModelsIndex: Int = -1

            @MetalBinding(name: "instanceData", function: .fragment)
            var fragmentMaterialsIndex: Int = -1
            @MetalBinding(name: "textureRotation", function: .fragment)
            var fragmentTextureRotation: Int = -1
            @MetalBinding(name: "cameraPosition", function: .fragment)
            var fragmentCameraPosition: Int = -1
            @MetalBinding(name: "textures", function: .fragment)
            var fragmentTexturesIndex: Int = -1
        }
        var bindings: Bindings
    }

    public var id: PassID
    public var enabled: Bool
    public var scene: SceneGraph

    public init(id: PassID, enabled: Bool = true, scene: SceneGraph) {
        self.id = id
        self.enabled = enabled
        self.scene = scene
    }

    public func setup(device: MTLDevice, configuration: some MetalConfigurationProtocol) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .main.bundle(forTarget: "RenderKitShaders", recursive: true)!)
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor(configuration)
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "UnlitShader::unlitVertexShader")
        let constantValues = MTLFunctionConstantValues(dictionary: [1: UInt32(1)])
        renderPipelineDescriptor.fragmentFunction = try library.makeFunction(name: "UnlitShader::unlitFragmentShader", constantValues: constantValues)
        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .less, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        renderPipelineDescriptor.label = "\(type(of: self))"
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(MDLVertexDescriptor.simpleVertexDescriptor)
        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
        var bindings = State.Bindings()
        try bindings.updateBindings(with: reflection)
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
                    guard let geometry = element.node.geometry, let material = geometry.materials.compactMap({ $0 as? PanoramaMaterial }).first else {
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
                            commandEncoder.setFragmentBytes(of: SIMD2<Float>.zero, index: bindings.fragmentTextureRotation)
                            commandEncoder.setFragmentBytes(of: helper.cameraMatrix.translation, index: bindings.fragmentCameraPosition)

                            if let texture = material.baseColorTexture {
                                commandEncoder.setFragmentBytes(of: UnlitShaderInstance(color: material.baseColorFactor, textureIndex: 0), index: bindings.fragmentMaterialsIndex)
                                commandEncoder.setFragmentTextures([texture], range: 0..<(bindings.fragmentTexturesIndex + 1))
                            } else {
                                commandEncoder.setFragmentBytes(of: UnlitShaderInstance(color: material.baseColorFactor, textureIndex: -1), index: bindings.fragmentMaterialsIndex)
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