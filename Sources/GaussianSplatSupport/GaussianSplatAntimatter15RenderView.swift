import BaseSupport
import Constraints3D
import GaussianSplatShaders
@preconcurrency import Metal
import MetalSupport
import os
import RenderKit
import simd
import SIMDSupport
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let splat = UTType(filenameExtension: "splat")!
}

public struct GaussianSplatAntimatter15DemoView: View {
    let splatCloud: SplatCloud<SplatX>

    public init(splatCloud: SplatCloud<SplatX>) {
        self.splatCloud = splatCloud
    }

    public var body: some View {
        GaussianSplatAntimatter15RenderView(splatCloud: splatCloud)
    }
}

public extension GaussianSplatAntimatter15DemoView {
    init(url: URL) {
        let data = try! Data(contentsOf: url)
        let splats = data.withUnsafeBytes { bytes in
            let splats = bytes.bindMemory(to: SplatB.self)
            return splats.map { SplatX($0) }
        }
        splatCloud = try! SplatCloud<SplatX>(device: MTLCreateSystemDefaultDevice()!, splats: splats)
    }
}

public extension GaussianSplatAntimatter15DemoView {
    init() {
        self = Self.trainSplats()
    }

    static func singleSplat() -> Self {
        let splatD = SplatD(position: [0, 0, 0], scale: [1, 1, 1], color: [1, 0, 0, 1], rotation: .identity)
        let splatB = SplatB(splatD)
        let splatX = SplatX(splatB)
        let splats = [splatX]
        let splatCloud = try! SplatCloud<SplatX>(device: MTLCreateSystemDefaultDevice()!, splats: splats)
        return .init(splatCloud: splatCloud)
    }

    static func trainSplats() -> Self {
        let url = Bundle.main.url(forResource: "train", withExtension: "splat")!
        return .init(url: url)
    }
}

// MARK: -

public struct GaussianSplatAntimatter15RenderView: View {
    @State
    private var pass: GaussianSplatAntimatter15RenderPass

    @State
    private var sortManager: AsyncSortManager<SplatX>

    @MainActor
    public init(splatCloud: SplatCloud<SplatX>) {
        let configuration = GaussianSplatAntimatter15RenderPass.Configuration(modelMatrix: .zero, cameraMatrix: .zero, debug: false)
        pass = GaussianSplatAntimatter15RenderPass(id: .init(CompositeHash("Antimatter15", false)), splatCloud: splatCloud, configuration: configuration)
        sortManager = try! AsyncSortManager(device: MTLCreateSystemDefaultDevice()!, splatCloud: splatCloud, capacity: splatCloud.capacity, logger: Logger())
    }

    public var body: some View {
        RenderView(pass: pass)
        .modifier(NewBallControllerViewModifier(constraint: .init(radius: 5), transform: $pass.configuration.cameraMatrix))
        .task {
            let channel = await sortManager.sortedIndicesChannel()
            for await sort in channel {
                pass.splatCloud.indexedDistances = sort
            }
        }
        .onChange(of: pass.configuration.debug, initial: true) {
            pass = GaussianSplatAntimatter15RenderPass(id: .init(CompositeHash("Antimatter15", pass.configuration.debug)), splatCloud: pass.splatCloud, configuration: pass.configuration)
        }
        .onChange(of: pass.configuration.cameraMatrix) {
            sortManager.requestSort(camera: pass.configuration.cameraMatrix, model: pass.configuration.modelMatrix, count: pass.splatCloud.count)
        }
        .inspector(isPresented: .constant(true)) {
            Form {
                Toggle("debug", isOn: $pass.configuration.debug)
                Button("Sort") {
                }
            }
        }
    }
}

// MARK: -

struct GaussianSplatAntimatter15RenderPass: RenderPassProtocol {
    @MetalBindings(function: .vertex)
    struct VertexBindings {
        var splats: Int = -1
        var indexedDistances: Int = -1
        var modelMatrix: Int = -1
        var viewMatrix: Int = -1
        var projectionMatrix: Int = -1
        var focal: Int = -1
        var viewport: Int = -1
    }

    struct State {
        var vertexBindings: VertexBindings
        var depthStencilState: MTLDepthStencilState
        var renderPipelineState: MTLRenderPipelineState
    }

    struct Configuration: Equatable {
        var modelMatrix: simd_float4x4
        var cameraMatrix: simd_float4x4
        var debug: Bool
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
        let constantValues = MTLFunctionConstantValues(dictionary: [1: self.configuration.debug])

        renderPipelineDescriptor.vertexFunction = try library.makeFunction(name: "GaussianSplatAntimatter15RenderShaders::vertexMain", constantValues: constantValues)
        renderPipelineDescriptor.fragmentFunction = try library.makeFunction(name: "GaussianSplatAntimatter15RenderShaders::fragmentMain", constantValues: constantValues)

        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add

        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha

        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

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

        let perspectiveProjection = PerspectiveProjection(verticalAngleOfView: .degrees(75), zClip: 0.2 ... 200)
        let projectionMatrix = perspectiveProjection.projectionMatrix(for: info.drawableSize)
        let f = min(info.drawableSize.x, info.drawableSize.y) / 4
        let focal = SIMD2<Float>(f, f)
        let drawableSize = info.drawableSize
        let viewMatrix = configuration.cameraMatrix.inverse

        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "\(type(of: self))", useDebugGroup: true) { commandEncoder in
            if info.configuration.depthStencilPixelFormat != .invalid {
                commandEncoder.setDepthStencilState(state.depthStencilState)
            }
            commandEncoder.setRenderPipelineState(state.renderPipelineState)
            if configuration.debug {
                commandEncoder.setTriangleFillMode(.lines)
            }
            commandEncoder.withDebugGroup("VertexShader") {
                let vertices: [SIMD2<Float>] = [
                    [-2, -2], [-2, 2], [2, -2], [2, 2]
                ]
                commandEncoder.setVertexBytes(of: vertices, index: 0)
                commandEncoder.setVertexBuffer(splatCloud.splats.unsafeBase, offset: 0, index: state.vertexBindings.splats)
                commandEncoder.setVertexBuffer(splatCloud.indexedDistances.indices.unsafeBase, offset: 0, index: state.vertexBindings.indexedDistances)

                commandEncoder.setVertexBytes(of: configuration.modelMatrix, index: state.vertexBindings.modelMatrix)
                commandEncoder.setVertexBytes(of: viewMatrix, index: state.vertexBindings.viewMatrix)
                commandEncoder.setVertexBytes(of: projectionMatrix, index: state.vertexBindings.projectionMatrix)
                commandEncoder.setVertexBytes(of: focal, index: state.vertexBindings.focal)
                commandEncoder.setVertexBytes(of: drawableSize, index: state.vertexBindings.viewport)
            }
            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: splatCloud.splats.count)
        }
    }
}
