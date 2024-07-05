import BaseSupport
import GaussianSplatShaders
import MetalKit
import MetalSupport
import RenderKit
import SIMDSupport

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
    var scene: SceneGraph
    var debugMode: Bool

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
//        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "GaussianSplatShaders::VertexPointShader")
//        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "GaussianSplatShaders::FragmentPointShader")

        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

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

    public func encode(device: MTLDevice, state: inout State, drawableSize: SIMD2<Float>, commandEncoder: any MTLRenderCommandEncoder) throws {
        let helper = SceneGraphRenderHelper(scene: scene, drawableSize: drawableSize)
        let elements = helper.elements()

        commandEncoder.setDepthStencilState(state.depthStencilState)
        commandEncoder.setRenderPipelineState(state.renderPipelineState)

//        commandEncoder.setCullMode(.back) // default is .none
//        commandEncoder.setFrontFacing(.clockwise) // default is .clockwise
        if debugMode {
            commandEncoder.setTriangleFillMode(.lines)
        }

        guard let camera = scene.currentCameraNode else {
            fatalError()
        }

        for element in elements {
            guard let splats = element.node.content as? Splats else {
                continue
            }

            let modelMatrix = element.modelMatrix
            let viewMatrix = helper.viewMatrix
            let projectionMatrix = helper.projectionMatrix
            let modelViewMatrix = element.modelViewProjectionMatrix
            let modelViewProjectionMatrix = element.modelViewProjectionMatrix

            let uniforms = GaussianSplatUniforms(
                modelViewProjectionMatrix: modelViewProjectionMatrix,
                modelViewMatrix: modelViewMatrix,
                projectionMatrix: projectionMatrix,
                modelMatrix: modelMatrix,
                viewMatrix: viewMatrix,
                cameraMatrix: camera.transform.matrix,
                cameraPosition: camera.transform.translation,
                drawableSize: drawableSize
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

            //        commandEncoder.draw(pointMesh, instanceCount: splatCount)
            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: splats.splats.count)
        }
    }
}
