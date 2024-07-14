import Everything
import Metal
import MetalKit
import MetalSupport
import MetalUISupport
import ModelIO
import os
import RenderKit
import RenderKitShadersLegacy
import Shapes2D
import SIMDSupport
import SwiftUI

struct VolumetricRenderPass: RenderPassProtocol {
    let id: AnyHashable = "VolumetricRenderPass"
    var scene: SceneGraph

    struct State: PassState {
        var renderPipelineState: MTLRenderPipelineState
        var depthStencilState: MTLDepthStencilState
    }

    func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .renderKitShadersLegacy)
        let vertexFunction = library.makeFunction(name: "volumeVertexShader")!
        let fragmentFunction = library.makeFunction(name: "volumeFragmentShader")

        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        let descriptor = VertexDescriptor.packed(semantics: [.position, .normal, .textureCoordinate])
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(descriptor)

        let renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)

        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilDescriptor.isDepthWriteEnabled = true
        let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
        return .init(renderPipelineState: renderPipelineState, depthStencilState: depthStencilState)
    }

    func encode(commandEncoder: MTLRenderCommandEncoder, state: inout State, drawableSize: SIMD2<Float>) {
        commandEncoder.setRenderPipelineState(state.renderPipelineState)
        commandEncoder.setDepthStencilState(state.depthStencilState)

        let helper = SceneGraphRenderHelper(scene: scene, drawableSize: drawableSize)
        for element in helper.elements() {
            guard let volumeRepresentation = element.node.content as? VolumeRepresentation else {
                continue
            }
            guard let cameraNode = scene.currentCameraNode else {
                fatalError("No camera")
            }
            // TODO: we need to remove this.
            let rollPitchYaw = cameraNode.transform.rotation.rollPitchYaw
            commandEncoder.setVertexBuffers(volumeRepresentation.mesh)
            // Vertex Buffer Index 1
            let cameraUniforms = CameraUniforms(projectionMatrix: helper.projectionMatrix)
            commandEncoder.setVertexBytes(of: cameraUniforms, index: 1)
            // Vertex Buffer Index 2
            let modelUniforms = VolumeTransforms(
                modelViewMatrix: element.modelViewMatrix,
                textureMatrix: simd_float4x4(translate: [0.5, 0.5, 0.5]) * rollPitchYaw.matrix4x4 * simd_float4x4(translate: [-0.5, -0.5, -0.5])
            )
            commandEncoder.setVertexBytes(of: modelUniforms, index: 2)
            // Vertex Buffer Index 3
            commandEncoder.setVertexBuffer(volumeRepresentation.instanceBuffer, offset: 0, index: 3)
            commandEncoder.setFragmentTexture(volumeRepresentation.texture, index: 0)
            commandEncoder.setFragmentTexture(volumeRepresentation.transferFunctionTexture, index: 1)
            // TODO: Hard coded
            let fragmentUniforms = VolumeFragmentUniforms(instanceCount: UInt16(volumeRepresentation.instanceCount), maxValue: 3_272, alpha: 10.0)
            commandEncoder.setFragmentBytes(of: fragmentUniforms, index: 0)
            commandEncoder.draw(volumeRepresentation.mesh, instanceCount: volumeRepresentation.instanceCount)
        }
    }
}

extension VolumetricRenderPass: Observable {
}
