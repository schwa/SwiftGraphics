import SwiftUI
import RenderKit
import SIMDSupport
import SwiftGraphicsSupport
import RenderKitShaders
import MetalSupport
import Shapes3D
import MetalKit
import simd

//struct SplatC {
//    var position: SIMD3<Float16>
//    var color: SIMD4<Float16>
//    var cov_a: SIMD3<Float16>
//    var cov_b: SIMD3<Float16>
//};


struct GaussianSplatView: View, DemoView {
    @State
    var splatCount: Int

    @State
    var splats: MTLBuffer

    @State
    var splatIndices: MTLBuffer

    @State
    var splatDistances: MTLBuffer

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
        let url = Bundle.module.url(forResource: "train.splatc", withExtension: "data")!
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

//        let splatSize = MemoryLayout<SplatC>.size
//        assert(splatSize == 26)
        print(Float(data.count) / 26)
        let splatSize = 26
        let splatCount = data.count / splatSize
        splats = device.makeBuffer(data: data, options: .storageModeShared)!.labelled("Splats")

        let splatIndicesData = (0 ..< splatCount).shuffled().map { UInt32($0) }.withUnsafeBytes {
            Data($0)
        }
        splatIndices = device.makeBuffer(data: splatIndicesData, options: .storageModeShared)!.labelled("Splats-Indices")
        print("#splats", splatCount);

        splatDistances = device.makeBuffer(length: MemoryLayout<Float>.size * splatCount, options: .storageModeShared)!.labelled("Splat-Distances")

        self.device = device
        self.splatCount = splatCount

        let size: Float = 0.005
        cube = try! Box3D(min: [-size, -size, -size], max: [size, size, size]).toMTKMesh(device: device)

//        debugSort()
    }

    var body: some View {
        RenderView(device: device, passes: passes)
        .ballRotation($modelTransform.rotation.rollPitchYaw, pitchLimit: .radians(-.infinity) ... .radians(.infinity))
        .overlay(alignment: .bottom) {
            Text("\(splatCount)")
            .foregroundStyle(.white)
            .padding()
        }
    }

    func debugSort() {
        device.capture(enabled: false) {
            print("START", CFAbsoluteTimeGetCurrent())
            print(Array(UnsafeBufferPointer<Float32>(start: splatDistances.contents().assumingMemoryBound(to: Float32.self), count: splatCount)[..<10]))
            let preCalcComputePass = GaussianSplatPreCalcComputePass(
                splatCount: splatCount,
                splatDistancesBuffer: Box(splatDistances),
                splatBuffer: Box(splats),
                modelMatrix: simd_float3x3(truncating: modelTransform.matrix),
                cameraPosition: cameraTransform.translation
            )
            try! preCalcComputePass.computeOnce(device: device)
            print(Array(UnsafeBufferPointer<Float32>(start: splatDistances.contents().assumingMemoryBound(to: Float32.self), count: splatCount)[..<10]))
            print("DONE", CFAbsoluteTimeGetCurrent())
        }



//        let before = UnsafeBufferPointer<UInt32>(start: splatIndices.contents().assumingMemoryBound(to: UInt32.self), count: splatCount)
//        print(Array(before[..<10]))
//        print("Unique indices before:", Set(before).count)
//        device.capture(enabled: false) {
//            let gaussianSplatSortComputePass = GaussianSplatBitonicSortComputePass(
//                splatCount: splatCount,
//                splatIndicesBuffer: Box(splatIndices),
//                splatDistancesBuffer: Box<splatDistances>
//            )
//            try! gaussianSplatSortComputePass.computeOnce(device: device)
//
//            let after = UnsafeBufferPointer<UInt32>(start: splatIndices.contents().assumingMemoryBound(to: UInt32.self), count: splatCount)
//            print(Array(after[..<10]))
//            print("Unique indices after:", Set(after).count)
//        }
    }

    var passes: [any PassProtocol] {

        let preCalcComputePass = GaussianSplatPreCalcComputePass(
            splatCount: splatCount,
            splatDistancesBuffer: Box(splatDistances),
            splatBuffer: Box(splats),
            modelMatrix: simd_float3x3(truncating: modelTransform.matrix),
            cameraPosition: cameraTransform.translation
        )

        let gaussianSplatSortComputePass = GaussianSplatBitonicSortComputePass(
            splatCount: splatCount,
            splatIndicesBuffer: Box(splatIndices),
            splatDistancesBuffer: Box(splatDistances)
        )

        let gaussianSplatRenderPass = GaussianSplatRenderPass(
            cameraTransform: cameraTransform,
            cameraProjection: cameraProjection,
            modelTransform: modelTransform,
            splatCount: splatCount,
            splats: Box(splats),
            splatIndices: Box(splatIndices),
            splatDistances: Box(splatDistances),
            pointMesh: cube
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

    func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .renderKitShaders)
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.label = "\(type(of: self))"
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(oneTrueVertexDescriptor)
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "GaussianSplatShader::VertexShader")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "GaussianSplatShader::FragmentShader")

        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha


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

    func encode(device: MTLDevice, state: State, drawableSize: SIMD2<Float>, commandEncoder: any MTLRenderCommandEncoder) throws {

        commandEncoder.setDepthStencilState(state.depthStencilState)
        commandEncoder.setRenderPipelineState(state.renderPipelineState)

        var uniforms = GaussianSplatUniforms()
        uniforms.modelViewProjectionMatrix = cameraProjection.projectionMatrix(for: drawableSize) * cameraTransform.matrix.inverse * modelTransform.matrix
        uniforms.modelMatrix = modelTransform.matrix
        uniforms.cameraPosition = cameraTransform.translation

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

        commandEncoder.draw(pointMesh, instanceCount: splatCount)
    }

}
