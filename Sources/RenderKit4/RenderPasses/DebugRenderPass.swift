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
        var drawableSize: SIMD2<Float> = [.nan, .nan]
        var depthStencilState: MTLDepthStencilState
        var renderPipelineState: MTLRenderPipelineState
    }

    public init(scene: SceneGraph) {
        self.scene = scene
    }

    public func setup(context: Context) throws -> State {
        let device = context.device

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = context.depthAttachmentPixelFormat

        let library = context.library
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "DebugVertexShader")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "DebugFragmentShader")
        renderPipelineDescriptor.label = "SmoothPanorama:\(type(of: self))"

        renderPipelineDescriptor.vertexDescriptor = vertexDescritor

        let renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)

        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .less, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(RenderKit4Error.generic("Could not create depth stencil state"))

        return State(depthStencilState: depthStencilState, renderPipelineState: renderPipelineState)
    }

    public func sizeWillChange(context: Context, state: inout State, size: CGSize) throws {
        state.drawableSize = .init(Float(size.width), Float(size.height))
    }

    public func render(context: Context, state: State, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: any MTLCommandBuffer) throws {
        let renderPassDescriptor = renderPassDescriptor.typedCopy()
        let commandEncoder = try commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor).safelyUnwrap(RenderKit4Error.resourceCreationFailure)
        defer {
            commandEncoder.endEncoding()
        }
        commandEncoder.label = "SmoothPanorama:\(type(of: self))"
        try encode(context: context, state: state, commandEncoder: commandEncoder)
    }

    public func encode(context: Context, state: State, commandEncoder: any MTLRenderCommandEncoder) throws {
        assert(state.drawableSize.x > 0 && state.drawableSize.y > 0)

        guard let cameraNode = scene.currentCameraNode else {
            fatalError("No camera node.")
        }
        guard let camera = cameraNode.content?.camera else {
            fatalError("No camera on camera node.")
        }

//        print(cameraNode.transform.rotation)

        let viewMatrix = cameraNode.transform.matrix.inverse
        let projectionMatrix = camera.projectionMatrix(aspectRatio: state.drawableSize.x / state.drawableSize.y)

        commandEncoder.setDepthStencilState(state.depthStencilState)
        commandEncoder.setCullMode(cullMode)
        commandEncoder.setFrontFacing(frontFacing)
        commandEncoder.setTriangleFillMode(triangleFillMode)
        commandEncoder.setRenderPipelineState(state.renderPipelineState)

        for node in scene.root.allNodes() {
            try commandEncoder.withDebugGroup("Node: \(node.id)") {
                guard let geometry = node.content?.geometry else {
                    return
                }
                let mesh = geometry.mesh

                let modelMatrix = node.transform.matrix
                let modelViewProjectionMatrix = projectionMatrix * viewMatrix * modelMatrix

                commandEncoder.withDebugGroup("FragmentShader") {
                    let fragmentUniforms = DebugFragmentShaderUniforms(windowSize: state.drawableSize)
                    commandEncoder.setFragmentBytes(of: fragmentUniforms, index: 0)
                }
                try commandEncoder.withDebugGroup("Node: \(node.id)") {
                    try commandEncoder.withDebugGroup("VertexShader") {
                        var vertexUniforms = DebugVertexShaderUniforms()
                        vertexUniforms.modelViewProjectionMatrix = modelViewProjectionMatrix
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
