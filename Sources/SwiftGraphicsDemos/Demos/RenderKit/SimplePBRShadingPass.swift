import BaseSupport
@preconcurrency import Metal
import ModelIO
import RenderKit
import RenderKitSceneGraph
import RenderKitShaders
import MetalSupport

struct SimplePBRShadingPass: RenderPassProtocol {
    struct State: PassState {
        var renderPipelineState: MTLRenderPipelineState
        var depthStencilState: MTLDepthStencilState

        @MetalBindings
        struct Bindings {
            @MetalBinding(name: "uniforms", function: .vertex)
            var vertexUniforms: Int
            @MetalBinding(name: "uniforms", function: .fragment)
            var fragmentUniforms: Int
            @MetalBinding(name: "material", function: .fragment)
            var fragmentMaterial: Int
            @MetalBinding(name: "light", function: .fragment)
            var fragmentLight: Int
        }
        var bindings: Bindings
    }

    var id: PassID
    var scene: SceneGraph

    func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .renderKitShaders)
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "SimplePBRShader::VertexShader")!
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "SimplePBRShader::FragmentShader")!
        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .less, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        renderPipelineDescriptor.label = "\(type(of: self))"

        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(MDLVertexDescriptor.simpleVertexDescriptor)

        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
        var bindings = State.Bindings(vertexUniforms: -1, fragmentUniforms: -1, fragmentMaterial: -1, fragmentLight: -1)
        try bindings.updateBindings(with: reflection)
        return State(renderPipelineState: renderPipelineState, depthStencilState: depthStencilState, bindings: bindings)
    }

    func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, state: State) throws {
        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "\(type(of: self))") { commandEncoder in
            try commandEncoder.withDebugGroup("Start encoding for \(type(of: self))") {
                let helper = try SceneGraphRenderHelper(scene: scene, targetColorAttachment: renderPassDescriptor.colorAttachments[0])
                commandEncoder.setDepthStencilState(state.depthStencilState)
                commandEncoder.setRenderPipelineState(state.renderPipelineState)
                let bindings = state.bindings
                for element in helper.elements() {
                    guard let geometry = element.node.geometry, let material = geometry.materials.compactMap({ $0 as? SimplePBRMaterial }).first else {
                        continue
                    }
                    commandEncoder.withDebugGroup("Node: \(element.node.id)") {
                        commandEncoder.withDebugGroup("VertexShader") {
                            let uniforms = SimplePBRVertexUniforms(
                                modelViewProjectionMatrix: element.modelViewProjectionMatrix,
                                modelMatrix: element.modelMatrix
                            )
                            commandEncoder.setVertexBytes(of: uniforms, index: bindings.vertexUniforms)
                        }

                        commandEncoder.withDebugGroup("FragmentShader") {
                            let uniforms = SimplePBRFragmentUniforms(cameraPosition: helper.scene.currentCameraNode!.transform.translation)
                            commandEncoder.setFragmentBytes(of: uniforms, index: bindings.fragmentUniforms)

                            commandEncoder.setFragmentBytes(of: material, index: bindings.fragmentMaterial)

                            let light = SimplePBRLight(position: [0, 0, 2], color: [1, 1, 1], intensity: 1)
                            commandEncoder.setFragmentBytes(of: light, index: bindings.fragmentLight)
                        }

                        assert(geometry.mesh.vertexBuffers.count == 1)
                        commandEncoder.draw(geometry.mesh)
                    }
                }
            }
        }
    }
}
