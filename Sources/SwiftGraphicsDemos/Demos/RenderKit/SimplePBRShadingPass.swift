import BaseSupport
@preconcurrency import Metal
import ModelIO
import RenderKit
import RenderKitSceneGraph
import RenderKitShaders

struct SimplePBRShadingPass: RenderPassProtocol {
    struct State: PassState {
        var renderPipelineState: MTLRenderPipelineState
        var depthStencilState: MTLDepthStencilState

        struct Bindings {
            var vertexBufferIndex: Int
            var vertexUniformsIndex: Int
            var fragmentUniformsIndex: Int
            var fragmentMaterialIndex: Int
            var fragmentLightIndex: Int
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
        guard let reflection else {
            fatalError("No reflection for render pipeline.")
        }
        let bindings = State.Bindings(
            vertexBufferIndex: try reflection.binding(for: "vertexBuffer.0", of: .vertex),
            vertexUniformsIndex: try reflection.binding(for: "uniforms", of: .vertex),
            fragmentUniformsIndex: try reflection.binding(for: "uniforms", of: .fragment),
            fragmentMaterialIndex: try reflection.binding(for: "material", of: .fragment),
            fragmentLightIndex: try reflection.binding(for: "light", of: .fragment)
        )

        return State(renderPipelineState: renderPipelineState, depthStencilState: depthStencilState, bindings: bindings)
    }

    func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, state: State) throws {
        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "\(type(of: self))") { commandEncoder in
            try commandEncoder.withDebugGroup("Start encoding for \(type(of: self))") {
                let helper = try SceneGraphRenderHelper(scene: scene, targetColorAttachment: renderPassDescriptor.colorAttachments[0])
                let elements = helper.elements()
                commandEncoder.setDepthStencilState(state.depthStencilState)
                commandEncoder.setRenderPipelineState(state.renderPipelineState)
                let bindings = state.bindings
                for element in elements {
                    guard let geometry = element.node.geometry, let material = geometry.materials.compactMap({ $0 as? SimplePBRMaterial }).first else {
                        continue
                    }
                    commandEncoder.withDebugGroup("Node: \(element.node.id)") {
                        commandEncoder.withDebugGroup("VertexShader") {
                            let uniforms = SimplePBRVertexUniforms(
                                modelViewProjectionMatrix: element.modelViewProjectionMatrix,
                                modelMatrix: element.modelMatrix
                            )
                            commandEncoder.setVertexBytes(of: uniforms, index: bindings.vertexUniformsIndex)
                        }

                        commandEncoder.withDebugGroup("FragmentShader") {
                            //                    let vertexBuffer = element.geometry.mesh.vertexBuffers[0]
                            //                    commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: bindings.vertexBufferIndex)

                            let uniforms = SimplePBRFragmentUniforms(cameraPosition: helper.scene.currentCameraNode!.transform.translation)
                            commandEncoder.setFragmentBytes(of: uniforms, index: bindings.fragmentUniformsIndex)

                            commandEncoder.setFragmentBytes(of: material, index: bindings.fragmentMaterialIndex)

                            let light = SimplePBRLight(position: [0, 0, 2], color: [1, 1, 1], intensity: 1)
                            commandEncoder.setFragmentBytes(of: light, index: bindings.fragmentLightIndex)

                            //                    if let texture = material.baseColorTexture {
                            //                        commandEncoder.setFragmentBytes(of: UnlitMaterial(color: material.baseColorFactor, textureIndex: 0), index: bindings.fragmentMaterialsIndex)
                            //                        commandEncoder.setFragmentTextures([texture], range: 0..<(bindings.fragmentTexturesIndex + 1))
                            //                    }
                        }

                        assert(geometry.mesh.vertexBuffers.count == 1)
                        commandEncoder.draw(geometry.mesh)
                    }
                }
            }
        }
    }
}
