import BaseSupport
import CoreGraphicsSupport
import GaussianSplatShaders
@preconcurrency import Metal
import MetalSupport
import os
import RenderKit
import simd
import SIMDSupport
import Spatial
import SwiftUI
import UniformTypeIdentifiers
import Widgets3D

struct GaussianSplatAntimatter15RenderPass: RenderPassProtocol {
    @MetalBindings(function: .vertex)
    struct VertexBindings {
        var splats: Int = -1
        var indexedDistances: Int = -1
        var modelMatrix: Int = -1
        var viewMatrix: Int = -1
        var projectionMatrix: Int = -1
        var viewport: Int = -1
        var scale: Int = -1
    }

    struct State {
        var vertexBindings: VertexBindings
        var depthStencilState: MTLDepthStencilState
        var renderPipelineState: MTLRenderPipelineState
    }

    struct Configuration: Equatable {
        enum DebugMode: Int32, CaseIterable {
            case off = 0
            case wireframe = 1
            case filled = 2
        }

        var modelMatrix: simd_float4x4
        var cameraMatrix: simd_float4x4
        var projection: PerspectiveProjection
        //        var blendConfiguration: BlendConfiguration = .init(
        //            sourceRGBBlendFactor: .sourceAlpha,
        //            destinationRGBBlendFactor: .oneMinusSourceAlpha,
        //            rgbBlendOperation: .add,
        //            sourceAlphaBlendFactor: .sourceAlpha,
        //            destinationAlphaBlendFactor: .oneMinusSourceAlpha,
        //            alphaBlendOperation: .add
        //        )
        var debugMode: DebugMode
        var splatScale: Float = 2.0
        var blendConfiguration: BlendConfiguration = .init(
            sourceRGBBlendFactor: .one,
            destinationRGBBlendFactor: .oneMinusSourceAlpha,
            rgbBlendOperation: .add,
            sourceAlphaBlendFactor: .one,
            destinationAlphaBlendFactor: .oneMinusSourceAlpha,
            alphaBlendOperation: .add
        )
    }

    struct BlendConfiguration: Hashable {
        var sourceRGBBlendFactor: MTLBlendFactor
        var destinationRGBBlendFactor: MTLBlendFactor
        var rgbBlendOperation: MTLBlendOperation
        var sourceAlphaBlendFactor: MTLBlendFactor
        var destinationAlphaBlendFactor: MTLBlendFactor
        var alphaBlendOperation: MTLBlendOperation
    }

    var id: PassID
    var splatCloud: SplatCloud<SplatX>
    var configuration: Configuration

    func setup(device: any MTLDevice, configuration: some RenderKit.MetalConfigurationProtocol) throws -> State {
        guard let bundle = Bundle.main.bundle(forTarget: "GaussianSplatShaders") else {
            throw BaseError.error(.missingResource)
        }
        let library = try device.makeDebugLibrary(bundle: bundle)
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor(configuration)
        renderPipelineDescriptor.label = "\(type(of: self))"

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.stride

        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        // TODO: Magic constant
        let constantValues = MTLFunctionConstantValues(dictionary: [2: self.configuration.debugMode.rawValue])

        renderPipelineDescriptor.vertexFunction = try library.makeFunction(name: "GaussianSplatAntimatter15RenderShaders::vertexMain", constantValues: constantValues)
        renderPipelineDescriptor.fragmentFunction = try library.makeFunction(name: "GaussianSplatAntimatter15RenderShaders::fragmentMain", constantValues: constantValues)

        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = self.configuration.blendConfiguration.rgbBlendOperation
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = self.configuration.blendConfiguration.alphaBlendOperation

        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = self.configuration.blendConfiguration.sourceRGBBlendFactor
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = self.configuration.blendConfiguration.sourceAlphaBlendFactor

        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = self.configuration.blendConfiguration.destinationRGBBlendFactor
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = self.configuration.blendConfiguration.destinationAlphaBlendFactor

        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
        guard let reflection else {
            throw BaseError.error(.resourceCreationFailure)
        }

        var vertexBindings = VertexBindings()
        try vertexBindings.updateBindings(with: reflection)

        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .always, isDepthWriteEnabled: false)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)

        return State(vertexBindings: vertexBindings, depthStencilState: depthStencilState, renderPipelineState: renderPipelineState)
    }

    func render(commandBuffer: any MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: RenderKit.PassInfo, state: State) throws {
        guard configuration.cameraMatrix != .zero else {
            print("Skipping pass - camera matrix is zero")
            return
        }
        let drawableSize = info.drawableSize
        //        print(drawableSize)
        let viewMatrix = configuration.cameraMatrix.inverse
        let modelMatrix = configuration.modelMatrix
        var projectionMatrix = configuration.projection.projectionMatrix(for: info.drawableSize)
        projectionMatrix[1][1] = -1

        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "\(type(of: self))", useDebugGroup: true) { commandEncoder in
            if info.configuration.depthStencilPixelFormat != .invalid {
                commandEncoder.setDepthStencilState(state.depthStencilState)
            }
            commandEncoder.setRenderPipelineState(state.renderPipelineState)
            if configuration.debugMode == .wireframe {
                commandEncoder.setTriangleFillMode(.lines)
            }
            commandEncoder.withDebugGroup("VertexShader") {
                let vertices: [SIMD2<Float>] = [
                    [-1, -1], [-1, 1], [1, -1], [1, 1]
                ]
                commandEncoder.setVertexBytes(of: vertices, index: 0)
                commandEncoder.setVertexBuffer(splatCloud.splats.unsafeBase, offset: 0, index: state.vertexBindings.splats)
                commandEncoder.setVertexBuffer(splatCloud.indexedDistances.indices.unsafeBase, offset: 0, index: state.vertexBindings.indexedDistances)

                commandEncoder.setVertexBytes(of: modelMatrix, index: state.vertexBindings.modelMatrix)
                commandEncoder.setVertexBytes(of: viewMatrix, index: state.vertexBindings.viewMatrix)
                commandEncoder.setVertexBytes(of: projectionMatrix, index: state.vertexBindings.projectionMatrix)
                commandEncoder.setVertexBytes(of: drawableSize, index: state.vertexBindings.viewport)
                commandEncoder.setVertexBytes(of: configuration.splatScale, index: state.vertexBindings.scale)
            }
            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: splatCloud.splats.count)
        }
    }
}
