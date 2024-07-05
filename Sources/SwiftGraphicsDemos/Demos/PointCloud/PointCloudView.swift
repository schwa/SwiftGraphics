import BaseSupport
import MetalKit
import MetalSupport
import RenderKit
import RenderKitShaders
import RenderKitUISupport
import Shapes3D
import SIMDSupport
import SwiftUI
import GaussianSplatSupport

// swiftlint:disable force_try

struct PointCloudView: View, DemoView {
    @State
    private var device: MTLDevice

    @State
    private var scene: SceneGraph

    @State
    private var pointCloud: PointCloud

    @State
    private var pointMesh: MTKMesh

    init() {
        let device = MTLCreateSystemDefaultDevice()!
        let url: URL = try! Bundle.main.url(forResource: "cube_points", withExtension: "pointsply")
        var ply = try! Ply(url: url)
        let points = try! ply.points
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
        RenderView(device: device, passes: passes)
        .onChange(of: pointCloud, initial: true) {
            scene.modify(label: "point-cloud") { node in
                node!.content = pointCloud
            }
        }
            .overlay(alignment: .bottom) {
                if let node = scene.node(for: "point-cloud"), let pointCloud = node.content as? PointCloud {
                    Text("\(pointCloud.count)")
                        .foregroundStyle(.white)
                        .padding()
                }
            }
            .toolbar {
                Button("Load Splat") {

                    let gaussianSplatsDemoBundle = Bundle.bundle(forProject: "SwiftGraphics", target: "GaussianSplatDemos")!

                    let url = gaussianSplatsDemoBundle.url(forResource: "train", withExtension: "splatc")!
                    let data = try! Data(contentsOf: url)
                    let points = data.withUnsafeBytes{ buffer in
                        let splats = buffer.bindMemory(to: SplatC.self)
                        return splats.map { SIMD3<Float>($0.position)}
                    }



                    self.pointCloud = PointCloud(count: points.count, points: .init(try! device.makeBuffer(bytesOf: points, options: .storageModeShared)), pointMesh: pointMesh)

                }

            }
            .modifier(SceneGraphViewModifier(device: device, scene: $scene, passes: passes))
    }
}

// TODO; Unchecked
struct PointCloud: Equatable, @unchecked Sendable {
    var count: Int
    // TODO: used typed buffer
    var points: BaseSupport.Box<MTLBuffer>
    var pointMesh: MTKMesh
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

    var scene: SceneGraph

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
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(BaseError.generic("Could not create depth stencil state"))

        return State(bindings: bindings, depthStencilState: depthStencilState, renderPipelineState: renderPipelineState)
    }

    func encode(device: MTLDevice, state: inout State, drawableSize: SIMD2<Float>, commandEncoder: any MTLRenderCommandEncoder) throws {
        let helper = SceneGraphRenderHelper(scene: scene, drawableSize: drawableSize)
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

extension Bundle {
    static func bundle(forProject project: String, target: String) -> Bundle? {
        let url = Bundle.main.url(forResource: "\(project)_\(target)", withExtension: "bundle")!
        let bundle = Bundle(url: url)
        return bundle
    }
}
