import BaseSupport
import GaussianSplatShaders
@preconcurrency import Metal
@preconcurrency import MetalKit
import MetalSupport
import Observation
import RenderKit
import RenderKitSceneGraph
import simd
import SIMDSupport
import SwiftUI
import UniformTypeIdentifiers

public struct GaussianSplatRenderPass: RenderPassProtocol {
    public struct State: PassState {
        var quadMesh: MTKMesh
        var vertexBindings: VertexBindings
        var fragmentBindings: FragmentBindings

        var depthStencilState: MTLDepthStencilState
        var renderPipelineState: MTLRenderPipelineState
        var vertexCounterBuffer: MTLBuffer
    }

    @MetalBindings(function: .vertex)
    struct VertexBindings {
        var uniforms: Int = -1
        var splats: Int = -1
        var indexedDistances: Int = -1
    }

    @MetalBindings(function: .fragment)
    struct FragmentBindings {
        var uniforms: Int = -1
    }


    public var id: PassID = "GaussianSplatRenderPass"
    public var scene: SceneGraph
    public var debugMode: Bool
    public var useVertexCounting = false
    public var discardRate: Float = 0.05

    init(scene: SceneGraph, debugMode: Bool, useVertexCounting: Bool = false, discardRate: Float) {
        self.scene = scene
        self.debugMode = debugMode
        self.useVertexCounting = useVertexCounting
        self.discardRate = discardRate
    }

    public func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let allocator = MTKMeshBufferAllocator(device: device)
        let quadMesh = try MTKMesh(mesh: MDLMesh(planeWithExtent: [2, 2, 0], segments: [1, 1], geometryType: .triangles, allocator: allocator), device: device)

        let constantValues = MTLFunctionConstantValues(dictionary: [0: useVertexCounting])

        let library = try device.makeDebugLibrary(bundle: .gaussianSplatShaders)
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.label = "\(type(of: self))"
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(MDLVertexDescriptor.simpleVertexDescriptor)
        renderPipelineDescriptor.vertexFunction = try library.makeFunction(name: "GaussianSplatShaders::VertexShader", constantValues: constantValues)
        renderPipelineDescriptor.fragmentFunction = try library.makeFunction(name: "GaussianSplatShaders::FragmentShader", constantValues: constantValues)

        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
        guard let reflection else {
            throw BaseError.resourceCreationFailure
        }

        var vertexBindings = VertexBindings()
        try vertexBindings.updateBindings(with: reflection)
        var fragmentBindings = FragmentBindings()
        try fragmentBindings.updateBindings(with: reflection)

        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .always, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)

        let vertexCounterBuffer = try device.makeBuffer(bytesOf: MyCounters(), options: .storageModeShared)
        vertexCounterBuffer.label = "vertexCounterBuffer"

        return State(quadMesh: quadMesh, vertexBindings: vertexBindings, fragmentBindings: fragmentBindings, depthStencilState: depthStencilState, renderPipelineState: renderPipelineState, vertexCounterBuffer: vertexCounterBuffer)
    }

    public func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, state: State) throws {
        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "\(type(of: self))", useDebugGroup: true) { commandEncoder in
            if info.configuration.depthStencilPixelFormat != .invalid {
                commandEncoder.setDepthStencilState(state.depthStencilState)
            }
            commandEncoder.setRenderPipelineState(state.renderPipelineState)
            if debugMode {
                commandEncoder.setTriangleFillMode(.lines)
            }
            let helper = try SceneGraphRenderHelper(scene: scene, targetColorAttachment: renderPassDescriptor.colorAttachments[0])
            guard let cameraTransform = scene.currentCameraNode?.transform else {
                throw BaseError.missingValue
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
                    drawableSize: try renderPassDescriptor.colorAttachments[0].size,
                    discardRate: discardRate
                )

                if useVertexCounting {
                    let b = state.vertexCounterBuffer.contents().bindMemory(to: MyCounters.self, capacity: 1)
                    print(splats.splats.count, b[0].vertices_submitted / 3, b[0].vertices_culled / 3, (b[0].vertices_submitted - b[0].vertices_culled) / 3)
                    state.vertexCounterBuffer.contents().storeBytes(of: MyCounters(), as: MyCounters.self)
                }

                commandEncoder.withDebugGroup("VertexShader") {
                    commandEncoder.setVertexBuffersFrom(mesh: state.quadMesh)
                    commandEncoder.setVertexBytes(of: uniforms, index: state.vertexBindings.uniforms)
                    commandEncoder.setVertexBuffer(splats.splats, offset: 0, index: state.vertexBindings.splats)
                    commandEncoder.setVertexBuffer(splats.indexedDistances[0], offset: 0, index: state.vertexBindings.indexedDistances)
// TODO: FIXME
                    //                    if useVertexCounting {
//                        commandEncoder.setVertexBuffer(state.vertexCounterBuffer, offset: 0, index: state.bindings.vertexCounterBuffer)
//                    }
                }
                commandEncoder.withDebugGroup("FragmentShader") {
                    commandEncoder.setFragmentBytes(of: uniforms, index: state.fragmentBindings.uniforms)
                }
                commandEncoder.draw(state.quadMesh, instanceCount: splats.splats.count)
            }
        }
    }
}

extension Node {
    var splats: SplatCloud? {
        content as? SplatCloud
    }
}

extension MTLRenderPassColorAttachmentDescriptor {
    var size: SIMD2<Float> {
        get throws {
            guard let texture else {
                throw BaseError.invalidParameter
            }
            return SIMD2<Float>(Float(texture.width), Float(texture.height))
        }
    }
}
