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

struct GaussianSplatRenderPass: RenderPassProtocol {
    struct State: PassState {
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

    var id: AnyHashable = "GaussianSplatRenderPass"

    var scene: SceneGraph
    var debugMode: Bool

    func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let allocator = MTKMeshBufferAllocator(device: device)
        let quadMesh = try MTKMesh(mesh: MDLMesh(planeWithExtent: [2, 2, 0], segments: [1, 1], geometryType: .triangles, allocator: allocator), device: device)

        let library = try device.makeDebugLibrary(bundle: .gaussianSplatShaders)
        print(library.functionNames)
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
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(BaseError.generic("Could not create depth stencil state"))

        return State(quadMesh: quadMesh, bindings: bindings, depthStencilState: depthStencilState, renderPipelineState: renderPipelineState)
    }

    func encode(device: MTLDevice, state: inout State, drawableSize: SIMD2<Float>, commandEncoder: any MTLRenderCommandEncoder) throws {
        commandEncoder.setDepthStencilState(state.depthStencilState)
        commandEncoder.setRenderPipelineState(state.renderPipelineState)

        commandEncoder.setCullMode(.back) // default is .none
        commandEncoder.setFrontFacing(.clockwise) // default is .clockwise
        if debugMode {
            commandEncoder.setTriangleFillMode(.lines)
        }

        let helper = SceneGraphRenderHelper(scene: scene, drawableSize: drawableSize)

        guard let cameraNode = scene.currentCameraNode, let camera = cameraNode.camera else {
            fatalError("No camera")
        }

        for element in helper.elements() {
            guard let splats = element.node.splats else {
                continue
            }

            let cameraTransform = cameraNode.transform
            let cameraProjection = cameraNode.camera!.projection
            let modelTransform = Transform.identity
            //            let splatCount = splats.splats.count
            //            let splats = splats.splats.base
            //            let splatIndices = splats.indices.base

            let uniforms = GaussianSplatUniforms(
                modelViewProjectionMatrix: cameraProjection.projectionMatrix(for: drawableSize) * cameraTransform.matrix.inverse * modelTransform.matrix,
                modelViewMatrix: cameraTransform.matrix.inverse * modelTransform.matrix,
                projectionMatrix: cameraProjection.projectionMatrix(for: drawableSize),
                modelMatrix: modelTransform.matrix,
                viewMatrix: cameraTransform.matrix.inverse,
                cameraMatrix: cameraTransform.matrix,
                cameraPosition: cameraTransform.translation,
                drawableSize: drawableSize
            )

            commandEncoder.withDebugGroup("VertexShader") {
                commandEncoder.setVertexBuffersFrom(mesh: state.quadMesh)
                commandEncoder.setVertexBytes(of: uniforms, index: state.bindings.vertexUniforms)
                commandEncoder.setVertexBuffer(splats.splats.base, offset: 0, index: state.bindings.vertexSplats)
                commandEncoder.setVertexBuffer(splats.indices.base, offset: 0, index: state.bindings.vertexSplatIndices)
            }
            commandEncoder.withDebugGroup("FragmentShader") {
                commandEncoder.setFragmentBytes(of: uniforms, index: state.bindings.fragmentUniforms)
                commandEncoder.setFragmentBuffer(splats.splats.base, offset: 0, index: state.bindings.fragmentSplats)
                commandEncoder.setFragmentBuffer(splats.indices.base, offset: 0, index: state.bindings.fragmentSplatIndices)
            }

            //        commandEncoder.draw(pointMesh, instanceCount: splatCount)
            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: splats.splats.count)
        }
    }
}

extension Node {
    var splats: Splats? {
        content as? Splats
    }
}
