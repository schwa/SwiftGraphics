import BaseSupport
import MetalKit
import MetalSupport
import RenderKitShadersLegacy
import SwiftUI

public struct DiffuseShadingRenderPass: RenderPassProtocol {
    // TODO: Move out
    public struct Material: MaterialProtocol {
        // TODO: Repalce with SIMD4
        var diffuseColor: CGColor
        var ambientColor: CGColor

        public init(diffuseColor: CGColor = .init(gray: 0, alpha: 1), ambientColor: CGColor = .init(gray: 0, alpha: 1)) {
            self.diffuseColor = diffuseColor
            self.ambientColor = ambientColor
        }
    }

    public var id: AnyHashable = "SceneGraph3RenderPass"
    public var scene: SceneGraph
    let vertexDescriptor = MTLVertexDescriptor(oneTrueVertexDescriptor)
    let lightAmbientColor = CGColor(gray: 1.0, alpha: 1.0)
    let lightDiffuseColor = CGColor(gray: 1.0, alpha: 1.0)
    let lightPosition: SIMD3<Float> = [0, 10, 0]
    let lightPower: Float = 16

    public struct State: PassState {
        var renderPipelineState: MTLRenderPipelineState
        var depthStencilState: MTLDepthStencilState
    }

    public init(scene: SceneGraph) {
        self.scene = scene
    }

    public func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .renderKitShadersLegacy)
        let useFlatShading = false
        let constantValues = MTLFunctionConstantValues(dictionary: [0: useFlatShading])
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = try library.makeFunction(name: "DiffuseShadingVertexShader", constantValues: constantValues)
        renderPipelineDescriptor.fragmentFunction = try library.makeFunction(name: "DiffuseShadingFragmentShader", constantValues: constantValues)
        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .less, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        renderPipelineDescriptor.label = "\(type(of: self))"

        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        let renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)

        return .init(renderPipelineState: renderPipelineState, depthStencilState: depthStencilState)
    }

    public func encode(commandEncoder: any MTLRenderCommandEncoder, info: PassInfo, state: inout State) {
        let elements = SceneGraphRenderHelper(scene: scene, drawableSize: info.drawableSize).elements()

        commandEncoder.setDepthStencilState(state.depthStencilState)
        let lightAmbientColor = lightAmbientColor.simd.xyz
        let lightDiffuseColor = lightDiffuseColor.simd.xyz

        for element in elements {
            guard let geometry = element.node.geometry, let material = geometry.materials.compactMap({ $0 as? Material }).first else {
                continue
            }

            commandEncoder.withDebugGroup("Node: \(element.node.id)") {
                commandEncoder.setRenderPipelineState(state.renderPipelineState)
                commandEncoder.withDebugGroup("FragmentShader") {
                    let materialDiffuseColor = material.diffuseColor.simd.xyz
                    let materialAmbientColor = material.ambientColor.simd.xyz
                    let uniforms = DiffuseShadingFragmentShaderUniforms(materialDiffuseColor: materialDiffuseColor, materialAmbientColor: materialAmbientColor, lightAmbientColor: lightAmbientColor, lightDiffuseColor: lightDiffuseColor, lightPosition: lightPosition, lightPower: lightPower)
                    commandEncoder.setFragmentBytes(of: uniforms, index: 0)
                }
                commandEncoder.withDebugGroup("Node: \(element.node.id)") {
                    commandEncoder.withDebugGroup("VertexShader") {
                        assert(geometry.mesh.vertexBuffers.count == 1)
                        let vertexBuffer = geometry.mesh.vertexBuffers[0]
                        commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
                        let uniforms = DiffuseShadingVertexShaderUniforms(modelViewMatrix: element.modelViewMatrix, modelViewProjectionMatrix: element.modelViewProjectionMatrix, modelNormalMatrix: element.modelNormalMatrix)
                        commandEncoder.setVertexBytes(of: uniforms, index: 1)
                    }
                    commandEncoder.draw(geometry.mesh)
                }
            }
        }
    }
}
