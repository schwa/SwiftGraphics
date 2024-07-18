import BaseSupport
import GaussianSplatShaders
@preconcurrency import Metal
@preconcurrency import MetalKit
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
            var myCounters: Int
        }
        var quadMesh: MTKMesh
        var bindings: Bindings
        var depthStencilState: MTLDepthStencilState
        var renderPipelineState: MTLRenderPipelineState
        var myCounters: MTLBuffer
    }

    public var id: PassID = "GaussianSplatRenderPass"
    public var scene: SceneGraph
    public var debugMode: Bool
    let useCounters = false

    public init(scene: SceneGraph, debugMode: Bool) {
        self.scene = scene
        self.debugMode = debugMode
    }

    public func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let allocator = MTKMeshBufferAllocator(device: device)
        let quadMesh = try MTKMesh(mesh: MDLMesh(planeWithExtent: [2, 2, 0], segments: [1, 1], geometryType: .triangles, allocator: allocator), device: device)

        let constantValues = MTLFunctionConstantValues(dictionary: [0: useCounters])

        let library = try device.makeDebugLibrary(bundle: .gaussianSplatShaders)
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.label = "\(type(of: self))"
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(oneTrueVertexDescriptor)
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
            fatalError("Failed to create render pipeline state")
        }

        let bindings = State.Bindings(
            vertexBuffer0: try reflection.binding(for: "vertexBuffer.0", of: .vertex),
            vertexUniforms: try reflection.binding(for: "uniforms", of: .vertex),
            vertexSplats: try reflection.binding(for: "splats", of: .vertex),
            vertexSplatIndices: try reflection.binding(for: "splatIndices", of: .vertex),
            fragmentUniforms: try reflection.binding(for: "uniforms", of: .fragment),
            fragmentSplats: try reflection.binding(for: "splats", of: .fragment),
            fragmentSplatIndices: try reflection.binding(for: "splatIndices", of: .fragment),
            myCounters: useCounters ? try reflection.binding(for: "my_counters", of: .vertex) : 0
        )

        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .always, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)

        let myCounters = try device.makeBuffer(bytesOf: MyCounters(), options: .storageModeShared)
        myCounters.label = "myCounters"

        return State(quadMesh: quadMesh, bindings: bindings, depthStencilState: depthStencilState, renderPipelineState: renderPipelineState, myCounters: myCounters)
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
                    drawableSize: try renderPassDescriptor.colorAttachments[0].size
                )

                if useCounters {
                    let b = state.myCounters.contents().bindMemory(to: MyCounters.self, capacity: 1)
                    print(splats.splats.count, b[0].vertices_submitted / 3, b[0].vertices_culled / 3, (b[0].vertices_submitted - b[0].vertices_culled) / 3)
                    state.myCounters.contents().storeBytes(of: MyCounters(), as: MyCounters.self)
                }



                commandEncoder.withDebugGroup("VertexShader") {
                    commandEncoder.setVertexBuffersFrom(mesh: state.quadMesh)
                    commandEncoder.setVertexBytes(of: uniforms, index: state.bindings.vertexUniforms)
                    commandEncoder.setVertexBuffer(splats.splats, index: state.bindings.vertexSplats)
                    commandEncoder.setVertexBuffer(splats.indices, index: state.bindings.vertexSplatIndices)
                    if useCounters {
                        commandEncoder.setVertexBuffer(state.myCounters, offset: 0, index: state.bindings.myCounters)
                    }
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
                throw BaseError.generic("Cannot get size for a color attachment with no texture.")
            }
            return SIMD2<Float>(Float(texture.width), Float(texture.height))
        }
    }
}
