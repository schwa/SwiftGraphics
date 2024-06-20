import SwiftUI
import RenderKit
import SIMDSupport
import SwiftGraphicsSupport
import RenderKitShaders
import MetalSupport
import Shapes3D
import MetalKit
import simd
import Observation
import Everything
import UniformTypeIdentifiers

extension UTType {
    static let splatC = UTType(filenameExtension: "splatc")!
}

struct GaussianSplatView: View, DemoView {

    @State
    var device = MTLCreateSystemDefaultDevice()!

    @State
    var viewModel: GaussianSplatViewModel?

    var body: some View {
        ZStack {
            Color.white
            if let viewModel {
                GaussianSplatRenderView(device: device).environment(viewModel)
            }
        }
        .toolbar {
            ValueView(value: false) { isPresented in
                Toggle("Load", isOn: isPresented)
                .fileImporter(isPresented: isPresented, allowedContentTypes: [.splatC]) { result in
                    if case let .success(url) = result {
                        viewModel = try! GaussianSplatViewModel(device: device, url: url)
                    }
                }
            }
        }
        .onAppear {
            let url = Bundle.module.url(forResource: "train.splatc", withExtension: "data")!
            viewModel = try! GaussianSplatViewModel(device: device, url: url)
        }

    }
}

@Observable
class GaussianSplatViewModel {
    var splatCount: Int
    var splats: MTLBuffer
    var splatIndices: MTLBuffer
    var splatDistances: MTLBuffer
    var cube: MTKMesh // TODO: RENAME

    init(device: MTLDevice, url: URL) throws {
        let data = try! Data(contentsOf: url)
        let splatSize = 26
        let splatCount = data.count / splatSize
        splats = device.makeBuffer(data: data, options: .storageModeShared)!.labelled("Splats")
        let splatIndicesData = (0 ..< splatCount).map { UInt32($0) }.withUnsafeBytes {
            Data($0)
        }
        splatIndices = device.makeBuffer(data: splatIndicesData, options: .storageModeShared)!.labelled("Splats-Indices")
        splatDistances = device.makeBuffer(length: MemoryLayout<Float>.size * splatCount, options: .storageModeShared)!.labelled("Splat-Distances")
        self.splatCount = splatCount

        let allocator = MTKMeshBufferAllocator(device: device)
        cube = try! MTKMesh(mesh: MDLMesh(planeWithExtent: [2, 2, 0], segments: [1, 1], geometryType: .triangles, allocator: allocator), device: device)
    }

}


struct GaussianSplatRenderView: View {
    @State
    var cameraTransform: Transform = .translation([0, 0, 3])

    @State
    var cameraProjection: Projection = .perspective(.init())

    @State
    var modelTransform: Transform = .init(scale: [1, 1, 1])

    @State
    var device: MTLDevice

    @State
    var debugMode: Bool = false

    @State
    var sortRate: Int = 1

    @Environment(GaussianSplatViewModel.self)
    var viewModel

    var body: some View {
        RenderView(device: device, passes: passes)
        .ballRotation($modelTransform.rotation.rollPitchYaw, pitchLimit: .radians(-.infinity) ... .radians(.infinity))
        .overlay(alignment: .bottom) {
            VStack {
                Text("#splats: \(viewModel.splatCount)")
                Slider(value: $cameraTransform.translation.z, in: 0.0 ... 20.0) { Text("Distance") }
                    .frame(maxWidth: 120)
                Toggle("Debug Mode", isOn: $debugMode)
                HStack {
                    Slider(value: $sortRate.toDouble, in: 1 ... 60) { Text("Sort Rate") }
                    .frame(maxWidth: 120)
                    Text("\(sortRate)")
                }

            }
            .padding()
            .background(.ultraThickMaterial).cornerRadius(8)
            .padding()
        }
    }

    var passes: [any PassProtocol] {
        let preCalcComputePass = GaussianSplatPreCalcComputePass(
            splatCount: viewModel.splatCount,
            splatDistancesBuffer: Box(viewModel.splatDistances),
            splatBuffer: Box(viewModel.splats),
            modelMatrix: simd_float3x3(truncating: modelTransform.matrix),
            cameraPosition: cameraTransform.translation
        )

        let gaussianSplatSortComputePass = GaussianSplatBitonicSortComputePass(
            splatCount: viewModel.splatCount,
            splatIndicesBuffer: Box(viewModel.splatIndices),
            splatDistancesBuffer: Box(viewModel.splatDistances),
            sortRate: sortRate
        )

        let gaussianSplatRenderPass = GaussianSplatRenderPass(
            cameraTransform: cameraTransform,
            cameraProjection: cameraProjection,
            modelTransform: modelTransform,
            splatCount: viewModel.splatCount,
            splats: Box(viewModel.splats),
            splatIndices: Box(viewModel.splatIndices),
            splatDistances: Box(viewModel.splatDistances),
            pointMesh: viewModel.cube,
            debugMode: debugMode
        )

        return [
            preCalcComputePass,
            gaussianSplatSortComputePass,
            gaussianSplatRenderPass
        ]
    }
}

// MARK: -

struct GaussianSplatRenderPass: RenderPassProtocol {
    struct State: PassState {
        struct Bindings {
            var vertexBuffer0: Int
            var vertexUniforms: Int
            var vertexSplats: Int
            var vertexSplatIndices: Int
            var fragmentUniforms: Int
            var fragmentSplats: Int
            var fragmentSplatIndices: Int
        }
        var bindings: Bindings
        var depthStencilState: MTLDepthStencilState
        var renderPipelineState: MTLRenderPipelineState
    }

    var id: AnyHashable = "GaussianSplatRenderPass"

    var cameraTransform: Transform
    var cameraProjection: Projection
    var modelTransform: Transform
    var splatCount: Int
    var splats: Box<MTLBuffer>
    var splatIndices: Box<MTLBuffer>
    var splatDistances: Box<MTLBuffer>
    var pointMesh: MTKMesh
    var debugMode: Bool

    func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .renderKitShaders)
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.label = "\(type(of: self))"
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(oneTrueVertexDescriptor)
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "GaussianSplatShader::VertexShader")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "GaussianSplatShader::FragmentShader")

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

        return State(bindings: bindings, depthStencilState: depthStencilState, renderPipelineState: renderPipelineState)
    }

    func encode(device: MTLDevice, state: inout State, drawableSize: SIMD2<Float>, commandEncoder: any MTLRenderCommandEncoder) throws {
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
            commandEncoder.setVertexBuffersFrom(mesh: pointMesh)
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
        commandEncoder.drawPrimitives(type: .triangleStrip,
                                     vertexStart: 0,
                                     vertexCount: 4,
                                     instanceCount: splatCount)

    }

}

extension Int {
var toDouble: Double {
    get {
        Double(self)
    }
    set {
        self = Int(newValue)
    }
}
}
