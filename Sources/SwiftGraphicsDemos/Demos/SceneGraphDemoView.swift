import Constraints3D
import Fields3D
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
        .modifier(enabled: false, FirstPerson3DGameControllerViewModifier(transform: $scene.unsafeCurrentCameraNode.transform))
        .modifier(enabled: false, CameraConeController(cameraCone: .init(apex: [0, 0, 0], axis: [0, 1, 0], h1: 0, r1: 2, r2: 2, h2: 2), transform: $scene.unsafeCurrentCameraNode.transform))
        .modifier(enabled: true, NewBallControllerViewModifier(constraint: .init(radius: 5), transform: $scene.unsafeCurrentCameraNode.transform))
        .overlay(alignment: .topTrailing) {
            RotationWidget(rotation: $scene.unsafeCurrentCameraNode.transform.rotation)
                .frame(width: 100, height: 100)
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
                                    Node(label: "camera", content: Camera())
                                        .transformed(translation: [0, 0, 5])
                                }
                                Node(label: "pano", content: Geometry(mesh: panoramaMesh, materials: [UnlitMaterialX(baseColorTexture: panoramaTexture)]))
                                Node(label: "models") {
                                    Node(label: "model-1", content: Geometry(mesh: sphere, materials: [DiffuseMaterial(diffuseColor: .red)]))
                                        .transformed(translation: [-1, 0, 0])
                                    Node(label: "model-2", content: Geometry(mesh: cylinder, materials: [DiffuseMaterial(diffuseColor: .green)]))
                                        .transformed(translation: [0, 0, 0])
                                    Node(label: "model-3", content: Geometry(mesh: cone, materials: [DiffuseMaterial(diffuseColor: .blue)]))
                                        .transformed(translation: [1, 0, 0])
                                        .transformed(.init(rotation: .rotation(angle: .degrees(45), axis: [1, 0, 0])))
                                    Node(label: "model-4", content: Geometry(mesh: quad, materials: [UnlitMaterialX(baseColorTexture: grassTexture)]))
                                        .transformed(scale: [10, 10, 10])
                                        .transformed(.init(rotation: .rotation(angle: .degrees(90), axis: [1, 0, 0])))
                                        .transformed(translation: [0, -1, 0])
                                }
                            }
        )
    }
}
