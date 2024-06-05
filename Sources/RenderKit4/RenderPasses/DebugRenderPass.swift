import Metal
import MetalKit
import Observation
import RenderKitShaders
import simd
import SwiftGraphicsSupport

public struct DebugRenderPass: RenderPassProtocol {
    public var id: AnyHashable = "DebugRenderPass2"

    public var positionOffset: SIMD3<Float> = [0, 0, -0.001]
    public var cullMode: MTLCullMode = .back
    public var frontFacing: MTLWinding = .clockwise
    public var triangleFillMode: MTLTriangleFillMode = .lines
    public var clipspaceOffset: SIMD3<Float> = .zero
    public var scene: SceneGraph

    var vertexDescritor = MTLVertexDescriptor(oneTrueVertexDescriptor)

    public struct State: RenderPassState {
        var depthStencilState: MTLDepthStencilState
        var renderPipelineState: MTLRenderPipelineState
    }

    public init(scene: SceneGraph) {
        self.scene = scene
    }

    public func setup(context: Context, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let device = context.device

        let library = context.library
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "DebugVertexShader")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "DebugFragmentShader")
        renderPipelineDescriptor.label = "\(type(of: self))"

        renderPipelineDescriptor.vertexDescriptor = vertexDescritor

        let renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)

        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .less, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(RenderKit4Error.generic("Could not create depth stencil state"))

        return State(depthStencilState: depthStencilState, renderPipelineState: renderPipelineState)
    }

    public func encode(context: Context, state: State, drawableSize: SIMD2<Float>, commandEncoder: MTLRenderCommandEncoder) throws {
        let elements = try SceneGraphRenderHelper(scene: scene, drawableSize: drawableSize).elements()

        commandEncoder.setDepthStencilState(state.depthStencilState)
        commandEncoder.setCullMode(cullMode)
        commandEncoder.setFrontFacing(frontFacing)
        commandEncoder.setTriangleFillMode(triangleFillMode)
        commandEncoder.setRenderPipelineState(state.renderPipelineState)

        for element in elements {
            try commandEncoder.withDebugGroup("Node: \(element.node.id)") {
                let mesh = element.geometry.mesh


                commandEncoder.withDebugGroup("FragmentShader") {
                    let fragmentUniforms = DebugFragmentShaderUniforms(windowSize: drawableSize)
                    commandEncoder.setFragmentBytes(of: fragmentUniforms, index: 0)
                }
                try commandEncoder.withDebugGroup("Node: \(element.node.id)") {
                    try commandEncoder.withDebugGroup("VertexShader") {
                        var vertexUniforms = DebugVertexShaderUniforms()
                        vertexUniforms.modelViewProjectionMatrix = element.modelViewProjectionMatrix
                        vertexUniforms.positionOffset = positionOffset
                        commandEncoder.setVertexBytes(of: vertexUniforms, index: 1)

                        let vertexBuffer = try mesh.vertexBuffers.first.safelyUnwrap(RenderKit4Error.resourceCreationFailure)
                        commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
                    }
                    commandEncoder.draw(mesh)
                }
            }
        }
    }
}
