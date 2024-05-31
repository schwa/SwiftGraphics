import MetalKit
import RenderKitShaders
import SwiftGraphicsSupport
import SwiftUI

public struct SimpleShadingRenderPass: RenderPassProtocol {
    public struct Material: SG3MaterialProtocol {
        var diffuseColor: CGColor
        var ambientColor: CGColor

        public init(diffuseColor: CGColor, ambientColor: CGColor) {
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

    public struct State: RenderPassState {
        var renderPipelineState: MTLRenderPipelineState
        var depthStencilState: MTLDepthStencilState
        var drawableSize: SIMD2<Float> = [.nan, .nan]
    }

    public init(scene: SceneGraph) {
        self.scene = scene
    }

    public func setup(context: Context) throws -> State {
        let device = context.device

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = context.depthAttachmentPixelFormat

        let library = context.renderContext.library
        let useFlatShading = false
        let constantValues = MTLFunctionConstantValues(dictionary: [0: useFlatShading])
        renderPipelineDescriptor.vertexFunction = try library.makeFunction(name: "SimpleShadingVertexShader", constantValues: constantValues)
        renderPipelineDescriptor.fragmentFunction = try library.makeFunction(name: "SimpleShadingFragmentShader", constantValues: constantValues)
        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .less, isDepthWriteEnabled: true)
        let depthStencilState = try context.device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(RenderKit4Error.generic("Could not create depth stencil state"))
        renderPipelineDescriptor.label = "SmoothPanorama:\(type(of: self))"

        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        let renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)

        return .init(renderPipelineState: renderPipelineState, depthStencilState: depthStencilState)
    }

    public func sizeWillChange(context: Context, state: inout State, size: CGSize) throws {
        state.drawableSize = .init(Float(size.width), Float(size.height))
    }

    public func render(context: Context, state: State, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) throws {
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        defer {
            commandEncoder.endEncoding()
        }
        try commandEncoder.withDebugGroup("Start encoding for \(type(of: self))") {
            commandEncoder.label = "\(type(of: self))"
            try encode(context: context, state: state, commandEncoder: commandEncoder)
        }
    }

    public func encode(context: Context, state: State, commandEncoder: any MTLRenderCommandEncoder) throws {
        assert(state.drawableSize.x > 0 && state.drawableSize.y > 0)

        commandEncoder.setDepthStencilState(state.depthStencilState)

        // TODO: too many bangs
        guard let currentCameraNode = scene.currentCameraNode else {
            return
        }

        let viewMatrix = currentCameraNode.transform.matrix.inverse
        let projectionMatrix = currentCameraNode.content!.camera!.projectionMatrix(aspectRatio: state.drawableSize.x / state.drawableSize.y)

        let lightAmbientColor = lightAmbientColor.simd.xyz
        let lightDiffuseColor = lightDiffuseColor.simd.xyz

        for node in scene.root.allNodes() {
            commandEncoder.withDebugGroup("Node: \(node.id)") {
                // TODO: Only doing one geometry
                guard let geometry = node.content?.geometry else {
                    return
                }
                // TODO: Only doing first material
                guard let material = geometry.materials[0] as? Material else {
                    return
                }
                commandEncoder.setRenderPipelineState(state.renderPipelineState)

                commandEncoder.withDebugGroup("FragmentShader") {
                    let materialDiffuseColor = material.diffuseColor.simd.xyz
                    let materialAmbientColor = material.ambientColor.simd.xyz
                    let uniforms = SimpleShadingFragmentShaderUniforms(materialDiffuseColor: materialDiffuseColor, materialAmbientColor: materialAmbientColor, lightAmbientColor: lightAmbientColor, lightDiffuseColor: lightDiffuseColor, lightPosition: lightPosition, lightPower: lightPower)
                    commandEncoder.setFragmentBytes(of: uniforms, index: 0)
                }
                commandEncoder.withDebugGroup("Node: \(node.id)") {
                    commandEncoder.withDebugGroup("VertexShader") {
                        assert(geometry.mesh.vertexBuffers.count == 1)
                        let vertexBuffer = geometry.mesh.vertexBuffers[0]
                        commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
                        let modelMatrix = node.transform.matrix
                        let modelViewMatrix = viewMatrix * modelMatrix
                        let modelViewProjectionMatrix = projectionMatrix * viewMatrix * modelMatrix
                        let modelNormalMatrix = simd_float3x3(truncating: node.transform.matrix).inverse
                        let uniforms = SimpleShadingVertexShaderUniforms(modelViewMatrix: modelViewMatrix, modelViewProjectionMatrix: modelViewProjectionMatrix, modelNormalMatrix: modelNormalMatrix)
                        commandEncoder.setVertexBytes(of: uniforms, index: 1)
                    }
                    commandEncoder.draw(geometry.mesh)
                }
            }
        }
    }
}
