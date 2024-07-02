import GaussianSplatShaders
import MetalKit
import RenderKit
import SIMDSupport
import SwiftGraphicsSupport

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

    var cameraTransform: Transform
    var cameraProjection: Projection
    var modelTransform: Transform
    var splatCount: Int
    var splats: Box<MTLBuffer>
    var splatIndices: Box<MTLBuffer>
    var debugMode: Bool

    public init(cameraTransform: Transform, cameraProjection: Projection, modelTransform: Transform, splatCount: Int, splats: Box<MTLBuffer>, splatIndices: Box<MTLBuffer>, debugMode: Bool) {
        self.cameraTransform = cameraTransform
        self.cameraProjection = cameraProjection
        self.modelTransform = modelTransform
        self.splatCount = splatCount
        self.splats = splats
        self.splatIndices = splatIndices
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
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(RenderKitError.generic("Could not create depth stencil state"))

        return State(quadMesh: quadMesh, bindings: bindings, depthStencilState: depthStencilState, renderPipelineState: renderPipelineState)
    }

    public func encode(device: MTLDevice, state: inout State, drawableSize: SIMD2<Float>, commandEncoder: any MTLRenderCommandEncoder) throws {
        commandEncoder.setDepthStencilState(state.depthStencilState)
        commandEncoder.setRenderPipelineState(state.renderPipelineState)

        commandEncoder.setCullMode(.back) // default is .none
        commandEncoder.setFrontFacing(.clockwise) // default is .clockwise
        if debugMode {
            commandEncoder.setTriangleFillMode(.lines)
        }

        let uniforms = GaussianSplatUniforms(
            modelViewProjectionMatrix: cameraProjection.projectionMatrix(for: drawableSize) * cameraTransform.matrix.inverse * modelTransform.matrix,
            modelViewMatrix: cameraTransform.matrix.inverse * modelTransform.matrix,
            projectionMatrix: cameraProjection.projectionMatrix(for: drawableSize),
            modelMatrix: modelTransform.matrix,
            viewMatrix: cameraTransform.matrix.inverse,
            cameraPosition: cameraTransform.translation,
            drawableSize: drawableSize
        )

        commandEncoder.withDebugGroup("VertexShader") {
            commandEncoder.setVertexBuffersFrom(mesh: state.quadMesh)
            commandEncoder.setVertexBytes(of: uniforms, index: state.bindings.vertexUniforms)
            commandEncoder.setVertexBuffer(splats.content, offset: 0, index: state.bindings.vertexSplats)
            commandEncoder.setVertexBuffer(splatIndices.content, offset: 0, index: state.bindings.vertexSplatIndices)
        }
        commandEncoder.withDebugGroup("FragmentShader") {
            commandEncoder.setFragmentBytes(of: uniforms, index: state.bindings.fragmentUniforms)
            commandEncoder.setFragmentBuffer(splats.content, offset: 0, index: state.bindings.fragmentSplats)
            commandEncoder.setFragmentBuffer(splatIndices.content, offset: 0, index: state.bindings.fragmentSplatIndices)
        }

        //        commandEncoder.draw(pointMesh, instanceCount: splatCount)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: splatCount)
    }
}
