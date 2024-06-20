import MetalKit
import RenderKitShadersLegacy
import SwiftGraphicsSupport
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
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(RenderKitError.generic("Could not create depth stencil state"))
        renderPipelineDescriptor.label = "\(type(of: self))"

        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        let renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)

        return .init(renderPipelineState: renderPipelineState, depthStencilState: depthStencilState)
    }

    public func encode(device: MTLDevice, state: inout State, drawableSize: SIMD2<Float>, commandEncoder: any MTLRenderCommandEncoder) throws {
        let elements = try SceneGraphRenderHelper(scene: scene, drawableSize: drawableSize).elements(material: Material.self)
        commandEncoder.setDepthStencilState(state.depthStencilState)
        let lightAmbientColor = lightAmbientColor.simd.xyz
        let lightDiffuseColor = lightDiffuseColor.simd.xyz
        for element in elements {
            guard let material = element.material else {
                fatalError()
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
                        assert(element.geometry.mesh.vertexBuffers.count == 1)
                        let vertexBuffer = element.geometry.mesh.vertexBuffers[0]
                        commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
                        let uniforms = DiffuseShadingVertexShaderUniforms(modelViewMatrix: element.modelViewMatrix, modelViewProjectionMatrix: element.modelViewProjectionMatrix, modelNormalMatrix: element.modelNormalMatrix)
                        commandEncoder.setVertexBytes(of: uniforms, index: 1)
                    }
                    commandEncoder.draw(element.geometry.mesh)
                }
            }
        }
    }
}
