import BaseSupport
import Constraints3D
import GaussianSplatSupport
@preconcurrency import Metal
import MetalKit
import MetalSupport
import Projection
import RenderKit
import RenderKitSceneGraph
import RenderKitShaders
import RenderKitUISupport
import Shapes3D
import SwiftUI

struct PointCloudView: View, DemoView {
    @State
    private var device: MTLDevice

    @State
    private var scene: SceneGraph

    @State
    private var pointCloud: PointCloud

    @State
    private var pointMesh: MTKMesh

    @State
    private var boundingBox = Box3D(min: [-2, -2, -2], max: [2, 2, 2])

    init() {
        let device = MTLCreateSystemDefaultDevice()!
        let url: URL = try! Bundle.main.url(forResource: "cube_points", withExtension: "pointsply")
        var ply = try! Ply(url: url)
        let points = try! ply.points
        let bounds = points.bounds
        boundingBox = Box3D(min: bounds.min, max: bounds.max)
        self.device = device
        var scene = SceneGraph.basicScene
        let size: Float = 0.001
        let pointMesh = try! Box3D(min: [-size, -size, -size], max: [size, size, size]).toMTKMesh(device: device)
        let node = Node(label: "point-cloud")
        scene.root.children.append(node)
        self.scene = scene
        self.pointMesh = pointMesh
        self.pointCloud = PointCloud(count: points.count, points: .init(try! device.makeBuffer(bytesOf: points, options: .storageModeShared)), pointMesh: pointMesh)
    }

    var body: some View {
        let passes = [PointCloudRenderPass(scene: scene)]
        ZStack {
            RenderView(passes: passes)
            Canvas { context, size in
                guard let cameraNode = scene.currentCameraNode, let camera = cameraNode.camera else {
                    return
                }
                let projection = Projection3DHelper(size: size, cameraProjection: camera.projection, cameraTransform: cameraNode.transform)
                context.draw3DLayer(projection: projection) { _, context3D in
                    context3D.drawAxisMarkers()
                    context3D.rasterize(options: Rasterizer.Options.default) { rasterizer in
                        for polygon in try! boundingBox.toPolygons() {
                            rasterizer.stroke(polygon: polygon.vertices.map(\.position), with: .color(.white))
                        }
                    }
                }
            }
        }
        .modifier(NewBallControllerViewModifier(constraint: .init(radius: 5), transform: $scene.unsafeCurrentCameraNode.transform))
        .onChange(of: pointCloud, initial: true) {
            do {
                try scene.modify(label: "point-cloud") { node in
                    node!.content = pointCloud
                }
            } catch {
                fatalError(error)
            }
        }
        .overlay(alignment: .bottom) {
            if let node = scene.firstNode(label: "point-cloud"), let pointCloud = node.content as? PointCloud {
                Text("\(pointCloud.count)")
                    .foregroundStyle(.white)
                    .padding()
            }
        }
        .toolbar {
            Button("Load Splat") {
                guard let bundle = Bundle.main.bundle(forTarget: "GaussianSplatShaders") else {
                    fatalError("Missing resource")
                }
                let url = bundle.url(forResource: "train", withExtension: "splatc")!
                let data = try! Data(contentsOf: url)
                let points = data.withUnsafeBytes { buffer in
                    let splats = buffer.bindMemory(to: SplatC.self)
                    return splats.map { SIMD3<Float>($0.position) }
                }

                pointCloud = PointCloud(count: points.count, points: .init(try! device.makeBuffer(bytesOf: points, options: .storageModeShared)), pointMesh: pointMesh)
            }
        }
    }
}

// MARK: -

// TODO; Unchecked
struct PointCloud: Equatable, @unchecked Sendable {
    var count: Int
    // TODO: used typed buffer
    var points: BaseSupport.Box<MTLBuffer>
    var pointMesh: MTKMesh
}

struct PointCloudRenderPass: RenderPassProtocol {
    struct State: Sendable {
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

    var id: PassID = "PointCloudRenderPass"
    var enabled = true

    var scene: SceneGraph

    func setup(device: MTLDevice, configuration: some MetalConfigurationProtocol) throws -> State {
        guard let bundle = Bundle.main.bundle(forTarget: "RenderKitShaders") else {
            throw BaseError.error(.missingResource)
        }
        let library = try device.makeDebugLibrary(bundle: bundle)
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor(configuration)
        renderPipelineDescriptor.label = "\(type(of: self))"
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(MDLVertexDescriptor.simpleVertexDescriptor)
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "PointCloudShader::VertexShader")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "PointCloudShader::FragmentShader")

        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
        guard let reflection else {
            throw BaseError.error(.resourceCreationFailure)
        }

        let bindings = State.Bindings(
            vertexBuffer0: try reflection.binding(for: "vertexBuffer.0", of: .vertex),
            vertexUniforms: try reflection.binding(for: "uniforms", of: .vertex),
            vertexInstancePositions: try reflection.binding(for: "positions", of: .vertex),
            fragmentUniforms: try reflection.binding(for: "uniforms", of: .fragment)
        )

        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .less, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)

        return State(bindings: bindings, depthStencilState: depthStencilState, renderPipelineState: renderPipelineState)
    }

    func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, state: State) throws {
        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "\(type(of: self))") { commandEncoder in
            try commandEncoder.withDebugGroup("Start encoding for \(type(of: self))") {
                let helper = try SceneGraphRenderHelper(scene: scene, targetColorAttachment: renderPassDescriptor.colorAttachments[0])
                let elements = helper.elements()

                for element in elements {
                    guard let pointCloud = element.node.content as? PointCloud else {
                        continue
                    }
                    commandEncoder.setDepthStencilState(state.depthStencilState)
                    commandEncoder.setRenderPipelineState(state.renderPipelineState)
                    commandEncoder.withDebugGroup("VertexShader") {
                        commandEncoder.setVertexBuffersFrom(mesh: pointCloud.pointMesh)
                        var vertexUniforms = PointCloudVertexUniforms()
                        vertexUniforms.modelViewProjectionMatrix = element.modelViewProjectionMatrix
                        commandEncoder.setVertexBytes(of: vertexUniforms, index: state.bindings.vertexUniforms)
                        commandEncoder.setVertexBuffer(pointCloud.points.content, offset: 0, index: state.bindings.vertexInstancePositions)
                    }
                    commandEncoder.withDebugGroup("FragmentShader") {
                        let fragmentUniforms = PointCloudFragmentUniforms()
                        commandEncoder.setFragmentBytes(of: fragmentUniforms, index: state.bindings.fragmentUniforms)
                    }
                    commandEncoder.draw(pointCloud.pointMesh, instanceCount: pointCloud.count)
                }
            }
        }
    }
}

extension Collection where Element == SIMD3<Float> {
    var bounds: (min: SIMD3<Float>, max: SIMD3<Float>) {
        // swiftlint:disable reduce_into
        ( reduce([Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude], SIMD3<Float>.min),
          reduce([-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude], SIMD3<Float>.max) )
    }
}

extension SIMD3<Float> {
    static func min(_ lhs: Self, _ rhs: Self) -> Self {
        [Swift.min(lhs.x, rhs.x), Swift.min(lhs.y, rhs.y), Swift.min(lhs.z, rhs.z)]
    }
    static func max(_ lhs: Self, _ rhs: Self) -> Self {
        [Swift.max(lhs.x, rhs.x), Swift.max(lhs.y, rhs.y), Swift.max(lhs.z, rhs.z)]
    }
}
