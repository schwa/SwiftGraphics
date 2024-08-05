import Metal
import MetalKit
import MetalSupport
import RenderKit
import RenderKitSceneGraph
import RenderKitUISupport
import Shapes3D
import simd
import SIMDSupport
import SwiftUI

struct SceneGraphDemoView: View, DemoView {
    @State
    private var scene: SceneGraph

    @State
    private var cameraConeConstraint = CameraConeConstraint(cameraCone: .init(apex: [0, 0, 0], axis: [0, 1, 0], apexToTopBase: 0, topBaseRadius: 2, bottomBaseRadius: 2, height: 2))

    init() {
        let device = MTLCreateSystemDefaultDevice()!
        let scene = try! SceneGraph.demo(device: device)
        self.scene = scene
    }

    var body: some View {
        RenderView(passes: [
            DiffuseShadingRenderPass(id: "diffuse", scene: scene),
            UnlitShadingPass(id: "unlit", scene: scene),
            DebugRenderPass(id: "debug", scene: scene),
        ])
        .rendererCallbacks { pass, _, passInfo in
            switch pass.id {
            case "diffuse":
                passInfo.currentRenderPassDescriptor!.colorAttachments[0].loadAction = .clear
                passInfo.currentRenderPassDescriptor!.depthAttachment.loadAction = .clear
                passInfo.currentRenderPassDescriptor!.colorAttachments[0].storeAction = .store
                passInfo.currentRenderPassDescriptor!.depthAttachment.storeAction = .store
            case "unlit":
                passInfo.currentRenderPassDescriptor!.colorAttachments[0].loadAction = .load
                passInfo.currentRenderPassDescriptor!.depthAttachment.loadAction = .load
                passInfo.currentRenderPassDescriptor!.colorAttachments[0].storeAction = .store
                passInfo.currentRenderPassDescriptor!.depthAttachment.storeAction = .store
            case "debug":
                passInfo.currentRenderPassDescriptor!.colorAttachments[0].loadAction = .load
                passInfo.currentRenderPassDescriptor!.depthAttachment.loadAction = .load
                passInfo.currentRenderPassDescriptor!.colorAttachments[0].storeAction = .store
                passInfo.currentRenderPassDescriptor!.depthAttachment.storeAction = .dontCare
            default:
                break
            }
        }
        .draggableParameter($cameraConeConstraint.height, axis: .vertical, range: 0...1, scale: 0.01, behavior: .clamping)
        .draggableParameter($cameraConeConstraint.angle.degrees, axis: .horizontal, range: 0...360, scale: 0.1, behavior: .wrapping)
        .onChange(of: cameraConeConstraint.position, initial: true) {
            let cameraPosition = cameraConeConstraint.position
            scene.currentCameraNode!.transform.matrix = look(at: cameraConeConstraint.lookAt, from: cameraPosition, up: [0, 1, 0])
        }
        .overlay(alignment: .bottom) {
            VStack {
                Text("\(cameraConeConstraint.height)")
                Text("\(cameraConeConstraint.angle)")
            }
            .padding()
            .background(Color.white)
            .padding()
        }
    }
}

extension SceneGraph {
    static func demo(device: MTLDevice) throws -> SceneGraph {
        let sphere = try Sphere3D(radius: 0.25).toMTKMesh(device: device)
        let cylinder = try Cylinder3D(radius: 0.25, height: 1).toMTKMesh(device: device)
        let cone = try Cone3D(height: 1, radius: 0.5).toMTKMesh(device: device)

        // TODO: this is ugly
        let panoramaMesh = try Sphere3D(radius: 400).toMTKMesh(device: device, inwardNormals: true)
        let loader = MTKTextureLoader(device: device)
        let panoramaTexture = try loader.newTexture(name: "BlueSkySkybox", scaleFactor: 2, bundle: Bundle.module)
        let grassTexture = try loader.newTexture(name: "grass_teal_block_256x", scaleFactor: 2, bundle: Bundle.module)

        let quad = try Quad<SimpleVertex>(x: -0.5, y: -0.5, width: 1, height: 1).toMTKMesh(device: device)
        return SceneGraph(root:
                            Node(label: "root") {
                                Node(label: "camera-ball") {
                                    Node(label: "camera")
                                        .content(Camera())
                                        .transform(translation: [0, 0, 5])
                                }
                                Node(label: "pano")
                                    .content(Geometry(mesh: panoramaMesh, materials: [UnlitMaterialX(baseColorTexture: panoramaTexture)]))
                                Node(label: "models") {
                                    Node(label: "model-1")
                                        .content(Geometry(mesh: sphere, materials: [DiffuseMaterial(diffuseColor: .red)]))
                                        .transform(translation: [-1, 0, 0])
                                    Node(label: "model-2")
                                        .content(Geometry(mesh: cylinder, materials: [DiffuseMaterial(diffuseColor: .green)]))
                                        .transform(translation: [0, 0, 0])
                                    Node(label: "model-3")
                                        .content(Geometry(mesh: cone, materials: [DiffuseMaterial(diffuseColor: .blue)]))
                                        .transform(translation: [1, 0, 0])
                                        .transform(.init(rotation: .rotation(angle: .degrees(45), axis: [1, 0, 0])))
                                    Node(label: "model-4")
                                        .content(Geometry(mesh: quad, materials: [UnlitMaterialX(baseColorTexture: grassTexture)]))
                                        .transform(scale: [10, 10, 10])
                                        .transform(.init(rotation: .rotation(angle: .degrees(90), axis: [1, 0, 0])))
                                        .transform(translation: [0, -1, 0])
                                }
                            }
        )
    }
}
