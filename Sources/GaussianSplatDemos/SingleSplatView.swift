import BaseSupport
import Everything
import Fields3D
import GaussianSplatShaders
import GaussianSplatSupport
@preconcurrency import Metal
@preconcurrency import MetalKit
import MetalSupport
import Observation
import RenderKit
import Shapes3D
import simd
import SIMDSupport
import SwiftFields
import SwiftUI
import UniformTypeIdentifiers

public struct SingleSplatView: View {
    @State
    private var cameraTransform: Transform = .translation([0, 0, 5])

    @State
    private var cameraProjection: Projection = .perspective(.init())

    @State
    private var ballConstraint = BallConstraint(radius: 5)

    @State
    private var modelTransform: Transform = .init(scale: [1, 1, 1])

    @State
    private var device: MTLDevice

    @State
    private var debugMode: Bool = false

    @State
    private var splat: SplatD

    @State
    private var randomSplats: [SplatD]

    @State
    private var passes: [any PassProtocol] = []

    public init() {
        let device = MTLCreateSystemDefaultDevice()!

        assert(MemoryLayout<SplatC>.size == 26)

        let splat = SplatD(position: [0, 0, 0], scale: [1, 0.5, 0.25], color: [1, 0, 1, 1], rotation: .init(angle: .zero, axis: [0, 0, 0]))

        self.device = device
        self.splat = splat

        var randomSplats: [SplatD] = []
        for z: Float in stride(from: -1, through: 1, by: 1) {
            for y: Float in stride(from: -1, through: 1, by: 1) {
                for x: Float in stride(from: -1, through: 1, by: 1) {
                    //                    let color: SIMD4<Float> = [Float.random(in: 0 ... 1), Float.random(in: 0 ... 1), Float.random(in: 0 ... 1), 1]
                    var color: SIMD4<Float> = [1, 1, 1, 1]
                    if x == -1 {
                        color = [1, 0, 0, 1]
                    }
                    if x == 0 {
                        color = [0, 1, 0, 1]
                        if y == -1 {
                            color = [1, 1, 1, 1]
                        }
                    }
                    if x == 1 {
                        color = [0, 0, 1, 1]
                    }

                    let rotation = Rotation(.init(
                        roll: .degrees(Double(x) * 0),
                        pitch: .degrees(Double(y) * 0),
                        yaw: .degrees(Double(z) * 0)
                    ))

                    let randomSplat = SplatD(position: .init([x, y, z] + [1, 1, 1]), scale: .init([0.2, 0.0, 0.0]), color: color, rotation: rotation)
                    randomSplats.append(randomSplat)
                }
            }
        }
        self.randomSplats = randomSplats
    }

    public var body: some View {
        RenderView(passes: passes)
            .ballRotation($ballConstraint.rollPitchYaw, updatesPitch: true, updatesYaw: true)
            .onChange(of: ballConstraint.transform, initial: true) {
                cameraTransform = ballConstraint.transform
                passes = makePasses()
            }
            .onChange(of: splat, initial: true) {
                passes = makePasses()
            }
            .inspector(isPresented: .constant(true)) {
                Form {
                    ValueView(value: false) { isPresented in
                        ValueView(value: Optional<Data>.none) { data in
                            Button("Save Splat") {
                                let splats = makeSplats().map(SplatB.init)
                                splats.withUnsafeBytes { buffer in
                                    data.wrappedValue = Data(buffer)
                                }
                                isPresented.wrappedValue = true
                            }
                            .fileExporter(isPresented: isPresented, item: data.wrappedValue/*, contentTypes: [.splat]*/) { _ in
                            }
                        }
                    }
                    ValueView(value: false) { expanded in
                        DisclosureGroup("Camera Transform", isExpanded: expanded) {
                            TransformEditor($cameraTransform)
                        }
                    }
                    ValueView(value: true) { expanded in
                        DisclosureGroup("Splat", isExpanded: expanded) {
                            Section("Splat Position") {
                                HStack {
                                    TextField("X", value: $splat.position.x, format: .number)
                                    TextField("Y", value: $splat.position.y, format: .number)
                                    TextField("Z", value: $splat.position.z, format: .number)
                                }
                                .labelsHidden()
                            }
                            Section("Splat Scale") {
                                HStack {
                                    TextField("X", value: $splat.scale.x, format: .number)
                                    TextField("Y", value: $splat.scale.y, format: .number)
                                    TextField("Z", value: $splat.scale.z, format: .number)
                                }
                                .labelsHidden()
                            }
                            Section("Splat Color") {
                                HStack {
                                    TextField("R", value: $splat.color.x, format: .number)
                                    TextField("G", value: $splat.color.y, format: .number)
                                    TextField("B", value: $splat.color.z, format: .number)
                                    TextField("A", value: $splat.color.w, format: .number)
                                }
                                .labelsHidden()
                            }
                            Section("Splat Rotation") {
                                RollPitchYawEditor($splat.rotation.rollPitchYaw)
                            }
                        }
                    }

                    ValueView(value: false) { expanded in
                        DisclosureGroup("Debug", isExpanded: expanded) {
                            Section("SplatB") {
                                Text("\(SplatB(splat))").monospaced()
                            }
                            Section("SplatC") {
                                Text("\(SplatC(splat))").monospaced()
                            }
                            Section("SplatD") {
                                Text("\(splat)").monospaced()
                            }
                        }
                    }
                }
                Toggle(isOn: $debugMode) {
                    Text("Debug")
                }
            }
    }

    func makeSplats() -> [SplatD] {
        //        + randomSplats

        //            .init(position: .init([-2, 0.01, 0.01]), scale: .init([0.5, 0.5, 0.5]), color: [1, 0, 1, 1], rotation: .identity),
        //            .init(position: .init([2, 0.01, 0.01]), scale: .init([0.5, 0.5, 0.5]), color: [1, 1, 0, 1], rotation: .identity),
        //            .init(position: .init([-3.01, 0.01, 0.01]), scale: .init([0.5, 0.5, 0.5]), color: [0, 1, 1, 1], rotation: .rollPitchYaw(.init(yaw: .degrees(90)))),

        [
            splat,
        ]
    }

    func makePasses() -> [any PassProtocol] {
        let splats = try! SplatCloud(device: device, splats: makeSplats().map(SplatC.init))

        let preCalcComputePass = GaussianSplatPreCalcComputePass(
            splats: splats,
            modelMatrix: simd_float3x3(truncating: .identity),
            cameraPosition: cameraTransform.translation
        )
        let gaussianSplatSortComputePass = GaussianSplatBitonicSortComputePass(
            splats: splats,
            sortRate: 1
        )
        let renderPass = SingleGaussianSplatRenderPass(cameraTransform: cameraTransform, cameraProjection: cameraProjection, modelTransform: modelTransform, splats: splats, debugMode: debugMode)
        return [
            preCalcComputePass,
            gaussianSplatSortComputePass,
            renderPass
        ]
    }
}

struct SingleGaussianSplatRenderPass: RenderPassProtocol {
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
        var quadMesh: MTKMesh
        var bindings: Bindings
        var depthStencilState: MTLDepthStencilState
        var renderPipelineState: MTLRenderPipelineState
    }

    var id: PassID = "GaussianSplatRenderPass"
    var cameraTransform: Transform
    var cameraProjection: Projection
    var modelTransform: Transform
    var splats: SplatCloud
    var debugMode: Bool

    func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let allocator = MTKMeshBufferAllocator(device: device)
        let quadMesh = try MTKMesh(mesh: MDLMesh(planeWithExtent: [2, 2, 0], segments: [1, 1], geometryType: .triangles, allocator: allocator), device: device)

        let library = try device.makeDebugLibrary(bundle: .gaussianSplatShaders)
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.label = "\(type(of: self))"
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(oneTrueVertexDescriptor)
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "GaussianSplatShaders::VertexShader")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "GaussianSplatShaders::FragmentShader")
        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
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

        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .always, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)

        return State(quadMesh: quadMesh, bindings: bindings, depthStencilState: depthStencilState, renderPipelineState: renderPipelineState)
    }

    func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, state: State) throws {
        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "\(type(of: self))", useDebugGroup: true) { commandEncoder in
            commandEncoder.setDepthStencilState(state.depthStencilState)
            commandEncoder.setRenderPipelineState(state.renderPipelineState)

            if debugMode {
                commandEncoder.setTriangleFillMode(.lines)
            }

            let projectionMatrix = cameraProjection.projectionMatrix(for: info.drawableSize)
            let viewMatrix = cameraTransform.matrix.inverse
            let modelMatrix = modelTransform.matrix

            let modelViewProjectionMatrix = projectionMatrix * viewMatrix * modelMatrix
            let modelViewMatrix = viewMatrix * modelMatrix
            let uniforms = GaussianSplatUniforms(
                modelViewProjectionMatrix: modelViewProjectionMatrix,
                modelViewMatrix: modelViewMatrix,
                projectionMatrix: projectionMatrix,
                viewMatrix: viewMatrix,
                cameraPosition: cameraTransform.matrix.translation,
                drawableSize: info.drawableSize
            )
            commandEncoder.withDebugGroup("VertexShader") {
                commandEncoder.setVertexBuffersFrom(mesh: state.quadMesh)
                commandEncoder.setVertexBytes(of: uniforms, index: state.bindings.vertexUniforms)
                commandEncoder.setVertexBuffer(splats.splats.base, offset: 0, index: state.bindings.vertexSplats)
                commandEncoder.setVertexBuffer(splats.indices.base, offset: 0, index: state.bindings.vertexSplatIndices)
            }
            commandEncoder.withDebugGroup("FragmentShader") {
                commandEncoder.setFragmentBytes(of: uniforms, index: state.bindings.fragmentUniforms)
                commandEncoder.setFragmentBuffer(splats.splats.base, offset: 0, index: state.bindings.fragmentSplats)
                commandEncoder.setFragmentBuffer(splats.indices.base, offset: 0, index: state.bindings.fragmentSplatIndices)
            }
            commandEncoder.draw(state.quadMesh, instanceCount: splats.splats.count)

            //        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: splats.splats.count)
        }
    }
}
