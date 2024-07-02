import MetalKit
import MetalSupport
import RenderKit
import RenderKitShaders
import Shapes3D
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI

// swiftlint:disable force_try

struct PointCloudView: View, DemoView {
    @State
    private var pointCount: Int

    @State
    private var points: MTLBuffer

    @State
    private var cameraTransform: Transform = .translation([0, 0, 2])

    @State
    private var cameraProjection: Projection = .perspective(.init())

    @State
    private var modelTransform: Transform = .init(scale: [1, 1, 1])

    @State
    private var device: MTLDevice

    @State
    private var cube: MTKMesh

    init() {
        let device = MTLCreateSystemDefaultDevice()!
        let url: URL = try! Bundle.main.url(forResource: "cube_points", withExtension: "pointsply")
        var ply = try! Ply(url: url)
        let points = try! ply.points

        self.device = device
        self.pointCount = points.count
        self.points = try! device.makeBuffer(bytesOf: points, options: .storageModeShared)

        let size: Float = 0.001
        cube = try! Box3D(min: [-size, -size, -size], max: [size, size, size]).toMTKMesh(device: device)
    }

    var body: some View {
        RenderView(device: device, passes: [PointCloudRenderPass(cameraTransform: cameraTransform, cameraProjection: cameraProjection, modelTransform: modelTransform, pointCount: pointCount, points: Box(points), pointMesh: cube)])
            .ballRotation($modelTransform.rotation.rollPitchYaw)
            .overlay(alignment: .bottom) {
                Text("\(pointCount)")
                    .foregroundStyle(.white)
                    .padding()
            }
    }
}

struct PointCloudRenderPass: RenderPassProtocol {
    struct State: PassState {
        struct Bindings {
            var vertexBuffer0: Int
            var vertexUniforms: Int
            var vertexInstancePositions: Int
            var fragmentUniforms: Int
        }
        var bindings: Bindings
        var depthStencilState: MTLDepthStencilState
        var renderPipelineState: MTLRenderPipelineState
    }

    var id: AnyHashable = "PointCloudRenderPass"

    var cameraTransform: Transform
    var cameraProjection: Projection
    var modelTransform: Transform
    var pointCount: Int
    var points: Box<MTLBuffer>
    var pointMesh: MTKMesh

    func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .renderKitShaders)
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.label = "\(type(of: self))"
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(oneTrueVertexDescriptor)
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "PointCloudShader::VertexShader")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "PointCloudShader::FragmentShader")

        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
        guard let reflection else {
            fatalError()
        }

        let bindings = State.Bindings(
            vertexBuffer0: try reflection.binding(for: "vertexBuffer.0", of: .vertex),
            vertexUniforms: try reflection.binding(for: "uniforms", of: .vertex),
            vertexInstancePositions: try reflection.binding(for: "positions", of: .vertex),
            fragmentUniforms: try reflection.binding(for: "uniforms", of: .fragment)
        )

        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .less, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(RenderKitError.generic("Could not create depth stencil state"))

        return State(bindings: bindings, depthStencilState: depthStencilState, renderPipelineState: renderPipelineState)
    }

    func encode(device: MTLDevice, state: inout State, drawableSize: SIMD2<Float>, commandEncoder: any MTLRenderCommandEncoder) throws {
        commandEncoder.setDepthStencilState(state.depthStencilState)
        commandEncoder.setRenderPipelineState(state.renderPipelineState)

        commandEncoder.withDebugGroup("VertexShader") {
            commandEncoder.setVertexBuffersFrom(mesh: pointMesh)

            var vertexUniforms = PointCloudVertexUniforms()
            vertexUniforms.modelViewProjectionMatrix = cameraProjection.projectionMatrix(for: drawableSize) * cameraTransform.matrix.inverse * modelTransform.matrix
            commandEncoder.setVertexBytes(of: vertexUniforms, index: state.bindings.vertexUniforms)

            commandEncoder.setVertexBuffer(points.content, offset: 0, index: state.bindings.vertexInstancePositions)
        }
        commandEncoder.withDebugGroup("FragmentShader") {
            let fragmentUniforms = PointCloudFragmentUniforms()
            commandEncoder.setFragmentBytes(of: fragmentUniforms, index: state.bindings.fragmentUniforms)
        }

        commandEncoder.draw(pointMesh, instanceCount: pointCount)
    }
}
