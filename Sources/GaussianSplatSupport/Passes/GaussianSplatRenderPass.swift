import BaseSupport
import GaussianSplatShaders
import MetalKit
import MetalSupport
import Observation
import RenderKit
import Shapes3D
import simd
import SIMDSupport
import SwiftUI
import UniformTypeIdentifiers

public struct GaussianSplatRenderPass: RenderPassProtocol {
    public struct State: PassState {
        struct Bindings {
            var vertexBuffer0: Int
            var vertexUniforms: Int
            var vertexSplats: Int
            var vertexSplatIndices: Int
            var fragmentUniforms: Int
            var fragmentSplats: Int
            var fragmentSplatIndices: Int
        }
        var quadMesh: MTKMesh
        var bindings: Bindings
        var depthStencilState: MTLDepthStencilState
        var renderPipelineState: MTLRenderPipelineState
    }

    public var id: AnyHashable = "GaussianSplatRenderPass"
    public var scene: SceneGraph
    public var debugMode: Bool

    public init(scene: SceneGraph, debugMode: Bool) {
        self.scene = scene
        self.debugMode = debugMode
    }

    public func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let allocator = MTKMeshBufferAllocator(device: device)
        let quadMesh = try MTKMesh(mesh: MDLMesh(planeWithExtent: [2, 2, 0], segments: [1, 1], geometryType: .triangles, allocator: allocator), device: device)

        let library = try device.makeDebugLibrary(bundle: .gaussianSplatShaders)
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.label = "\(type(of: self))"
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(oneTrueVertexDescriptor)
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "GaussianSplatShaders::VertexShader")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "GaussianSplatShaders::FragmentShader")

        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        //        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .oneMinusDestinationAlpha
        //        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .oneMinusDestinationAlpha
        //        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        //        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one

        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
        guard let reflection else {
            fatalError()
        }

        let bindings = State.Bindings(
            vertexBuffer0: try reflection.binding(for: "vertexBuffer.0", of: .vertex),
            vertexUniforms: try reflection.binding(for: "uniforms", of: .vertex),
            vertexSplats: try reflection.binding(for: "splats", of: .vertex),
            vertexSplatIndices: try reflection.binding(for: "splatIndices", of: .vertex),
            fragmentUniforms: try reflection.binding(for: "uniforms", of: .fragment),
            fragmentSplats: try reflection.binding(for: "splats", of: .fragment),
            fragmentSplatIndices: try reflection.binding(for: "splatIndices", of: .fragment)
        )

        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .always, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)

        return State(quadMesh: quadMesh, bindings: bindings, depthStencilState: depthStencilState, renderPipelineState: renderPipelineState)
    }

    public func encode(commandEncoder: any MTLRenderCommandEncoder, info: PassInfo, state: inout State) {
        commandEncoder.setDepthStencilState(state.depthStencilState)
        commandEncoder.setRenderPipelineState(state.renderPipelineState)
        //        commandEncoder.setCullMode(.back) // default is .none
        //        commandEncoder.setFrontFacing(.counterClockwise) // default is .clockwise
        if debugMode {
            commandEncoder.setTriangleFillMode(.lines)
        }
        let helper = SceneGraphRenderHelper(scene: scene, drawableSize: info.drawableSize)
        guard let cameraTransform = scene.currentCameraNode?.transform else {
            fatalError("No camera")
        }
        for element in helper.elements() {
            guard let splats = element.node.splats else {
                continue
            }
            let uniforms = GaussianSplatUniforms(
                modelViewProjectionMatrix: helper.projectionMatrix * cameraTransform.matrix.inverse * element.modelMatrix,
                modelViewMatrix: helper.cameraMatrix.inverse * element.modelMatrix,
                projectionMatrix: helper.projectionMatrix,
                viewMatrix: helper.cameraMatrix.inverse,
                cameraPosition: helper.cameraMatrix.translation,
                drawableSize: info.drawableSize
            )

            commandEncoder.withDebugGroup("VertexShader") {
                commandEncoder.setVertexBuffersFrom(mesh: state.quadMesh)
                commandEncoder.setVertexBytes(of: uniforms, index: state.bindings.vertexUniforms)
                commandEncoder.setVertexBuffer(splats.splats, index: state.bindings.vertexSplats)
                commandEncoder.setVertexBuffer(splats.indices, index: state.bindings.vertexSplatIndices)
            }
            commandEncoder.withDebugGroup("FragmentShader") {
                commandEncoder.setFragmentBytes(of: uniforms, index: state.bindings.fragmentUniforms)
                commandEncoder.setFragmentBuffer(splats.splats, index: state.bindings.fragmentSplats)
                commandEncoder.setFragmentBuffer(splats.indices, index: state.bindings.fragmentSplatIndices)
            }
            commandEncoder.draw(state.quadMesh, instanceCount: splats.splats.count)
        }
    }
}

extension Node {
    var splats: SplatCloud? {
        content as? SplatCloud
    }
}
