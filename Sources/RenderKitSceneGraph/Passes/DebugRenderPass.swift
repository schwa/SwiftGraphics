import BaseSupport
@preconcurrency import Metal
import MetalKit
import MetalSupport
import ModelIO
import Observation
import RenderKit
import RenderKitShaders
import simd

public struct DebugRenderPass: RenderPassProtocol {
    public var id: PassID
    public var enabled: Bool

    public var positionOffset: SIMD3<Float> = [0, 0, -0.001]
    public var cullMode: MTLCullMode = .back
    public var frontFacing: MTLWinding = .clockwise
    public var triangleFillMode: MTLTriangleFillMode = .lines
    public var clipspaceOffset: SIMD3<Float> = .zero
    public var scene: SceneGraph

    let vertexDescriptor = MTLVertexDescriptor(MDLVertexDescriptor.simpleVertexDescriptor)

    public struct State: Sendable {
        var depthStencilState: MTLDepthStencilState
        var renderPipelineState: MTLRenderPipelineState
    }

    public init(id: PassID, enabled: Bool = true, scene: SceneGraph) {
        self.id = id
        self.enabled = enabled
        self.scene = scene
    }

    public func setup(device: MTLDevice, configuration: some MetalConfigurationProtocol) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .renderKitShaders)
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor(configuration)
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "DebugVertexShader")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "DebugFragmentShader")
        renderPipelineDescriptor.label = "\(type(of: self))"

        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor

        let renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)

        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .less, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)

        return State(depthStencilState: depthStencilState, renderPipelineState: renderPipelineState)
    }

    public func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, state: State) throws {
        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "\(type(of: self))") { commandEncoder in
            try commandEncoder.withDebugGroup("Start encoding for \(type(of: self))") {
                let elements = try SceneGraphRenderHelper(scene: scene, targetColorAttachment: renderPassDescriptor.colorAttachments[0]).elements()
                commandEncoder.setDepthStencilState(state.depthStencilState)
                commandEncoder.setCullMode(cullMode)
                commandEncoder.setFrontFacing(frontFacing)
                commandEncoder.setTriangleFillMode(triangleFillMode)
                commandEncoder.setRenderPipelineState(state.renderPipelineState)
                for element in elements {
                    guard let mesh = element.node.geometry?.mesh else {
                        continue
                    }
                    try commandEncoder.withDebugGroup("Node: \(element.node.id)") {
                        commandEncoder.withDebugGroup("FragmentShader") {
                            let fragmentUniforms = DebugFragmentShaderUniforms(windowSize: info.drawableSize)
                            commandEncoder.setFragmentBytes(of: fragmentUniforms, index: 0)
                        }
                        try commandEncoder.withDebugGroup("Node: \(element.node.id)") {
                            try commandEncoder.withDebugGroup("VertexShader") {
                                var vertexUniforms = DebugVertexShaderUniforms()
                                vertexUniforms.modelViewProjectionMatrix = element.modelViewProjectionMatrix
                                vertexUniforms.positionOffset = positionOffset
                                commandEncoder.setVertexBytes(of: vertexUniforms, index: 1)

                                let vertexBuffer = try mesh.vertexBuffers.first.safelyUnwrap(BaseError.resourceCreationFailure)
                                commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
                            }
                            commandEncoder.draw(mesh)
                        }
                    }
                }
            }
        }
    }
}
