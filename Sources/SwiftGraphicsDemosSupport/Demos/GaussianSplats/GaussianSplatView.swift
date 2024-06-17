import SwiftUI
import RenderKit
import SIMDSupport
import SwiftGraphicsSupport
import RenderKitShaders
import MetalSupport
import Shapes3D
import MetalKit
import simd

struct Splat {
    var position: PackedFloat3 // 3 floats for position (x, y, z)
    var scales: PackedFloat3   // 3 floats for scales (exp(scale_0), exp(scale_1), exp(scale_2))
    var color: SIMD4<UInt8>    // 4 uint8_t for color (r, g, b, opacity)
    var rot: SIMD4<UInt8>      // 4 uint8_t for normalized rotation (rot_0, rot_1, rot_2, rot_3) scaled to [0, 255]
};

struct GaussianSplatView: View, DemoView {
    @State
    var splatCount: Int

    @State
    var splats: MTLBuffer

    @State
    var splatIndices: MTLBuffer

    @State
    var cameraTransform: Transform = .translation([0, 0, 2])

    @State
    var cameraProjection: Projection = .perspective(.init())

    @State
    var modelTransform: Transform = .init(scale: [1, 1, 1])

    @State
    var device: MTLDevice

    @State
    var cube: MTKMesh

    init() {
        let device = MTLCreateSystemDefaultDevice()!

        let url = Bundle.module.url(forResource: "train", withExtension: "splat")!
        var data = try! Data(contentsOf: url)


//        data.withUnsafeMutableBytes { buffer in
//            let splats = buffer.bindMemory(to: Splat.self)
//            let flipY = true
//            if flipY {
//                let bounds = splats.map(\.position).bounds
//                print(bounds)
//                for index in 0..<splats.count {
//                    splats[index].position.y = bounds.max.y - (splats[index].position.y - bounds.min.y)
//                    splats[index].position.y -= (bounds.min.y + bounds.max.y) / 2
//                }
//                print(splats.map(\.position).bounds)
////                let newPositions = splats.map(\.position)
////                let newMin = newPositions.reduce([Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude], min)
////                let newMax = newPositions.reduce([-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude], max)
////                print(newMin.y, newMax.y)
//
//            }
//
//        }




        let splatSize = MemoryLayout<Splat>.size
        assert(splatSize == 32)
        let splatCount = data.count / splatSize
        splats = device.makeBuffer(data: data, options: .storageModeShared)!

        let splatIndicesData = (0 ..< splatCount).map { UInt32($0) }.withUnsafeBytes {
            Data($0)
        }
        splatIndices = device.makeBuffer(data: splatIndicesData, options: .storageModeShared)!


        self.device = device
        self.splatCount = splatCount

        let size: Float = 0.005
        cube = try! Box3D(min: [-size, -size, -size], max: [size, size, size]).toMTKMesh(device: device)
    }

    var body: some View {

        let renderPass = GaussianSplatRenderPass(
            cameraTransform: cameraTransform,
            cameraProjection: cameraProjection,
            modelTransform: modelTransform,
            splatCount: splatCount,
            splats: Box(splats),
            splatIndices: Box(splatIndices),
            pointMesh: cube
        )

        RenderView(renderPasses: [renderPass])
            .renderContext(RenderContext(device: device, library: try! device.makeDebugLibrary(bundle: .renderKitShaders)))
            .ballRotation($modelTransform.rotation.rollPitchYaw, pitchLimit: .radians(-.infinity) ... .radians(.infinity))
            .overlay(alignment: .bottom) {
                Text("\(splatCount)")
                .foregroundStyle(.white)
                .padding()
            }
    }
}

extension Collection where Element == PackedFloat3 {
    var bounds: (min: PackedFloat3, max: PackedFloat3) {
        return (
            reduce([Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude], SwiftGraphicsDemosSupport.min),
            reduce([-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude], SwiftGraphicsDemosSupport.max)
        )
    }
}

func max(lhs: PackedFloat3, rhs: PackedFloat3) -> PackedFloat3 {
    [max(lhs[0], rhs[0]), max(lhs[1], rhs[1]), max(lhs[2], rhs[2])]
}

func min(lhs: PackedFloat3, rhs: PackedFloat3) -> PackedFloat3 {
    [min(lhs[0], rhs[0]), min(lhs[1], rhs[1]), min(lhs[2], rhs[2])]
}


func max(lhs: SIMD3<Float>, rhs: SIMD3<Float>) -> SIMD3<Float> {
    [max(lhs[0], rhs[0]), max(lhs[1], rhs[1]), max(lhs[2], rhs[2])]
}

func min(lhs: SIMD3<Float>, rhs: SIMD3<Float>) -> SIMD3<Float> {
    [min(lhs[0], rhs[0]), min(lhs[1], rhs[1]), min(lhs[2], rhs[2])]
}

struct GaussianSplatRenderPass: RenderPassProtocol {

    struct State: RenderPassState {
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
    var pointMesh: MTKMesh

    func setup(context: Context, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let device = context.device

        let library = context.library
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.label = "\(type(of: self))"
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(oneTrueVertexDescriptor)
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "GaussianSplatShader::VertexShader")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "GaussianSplatShader::FragmentShader")

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

        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .less, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(RenderKitError.generic("Could not create depth stencil state"))

        return State(bindings: bindings, depthStencilState: depthStencilState, renderPipelineState: renderPipelineState)
    }

    func encode(context: Context, state: State, drawableSize: SIMD2<Float>, commandEncoder: any MTLRenderCommandEncoder) throws {

        commandEncoder.setDepthStencilState(state.depthStencilState)
        commandEncoder.setRenderPipelineState(state.renderPipelineState)


        try commandEncoder.withDebugGroup("VertexShader") {
            commandEncoder.setVertexBuffersFrom(mesh: pointMesh)

            var vertexUniforms = GaussianSplatVertexUniforms()
            vertexUniforms.modelViewProjectionMatrix = cameraProjection.projectionMatrix(for: drawableSize) * cameraTransform.matrix.inverse * modelTransform.matrix
            commandEncoder.setVertexBytes(of: vertexUniforms, index: state.bindings.vertexUniforms)

            commandEncoder.setVertexBuffer(splats.content, offset: 0, index: state.bindings.vertexSplats)
            commandEncoder.setVertexBuffer(splatIndices.content, offset: 0, index: state.bindings.vertexSplatIndices)
        }
        commandEncoder.withDebugGroup("FragmentShader") {
            let fragmentUniforms = GaussianSplatFragmentUniforms()
            commandEncoder.setFragmentBytes(of: fragmentUniforms, index: state.bindings.fragmentUniforms)
            commandEncoder.setFragmentBuffer(splats.content, offset: 0, index: state.bindings.fragmentSplats)
            commandEncoder.setFragmentBuffer(splatIndices.content, offset: 0, index: state.bindings.fragmentSplatIndices)
        }

        commandEncoder.draw(pointMesh, instanceCount: splatCount)
    }

}
