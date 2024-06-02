import Metal
import RenderKit4
import Shapes3D
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI
import MetalKit

public struct SceneGraphDemoView: View, DemoView {
    let device: MTLDevice

    @State
    var scene: SceneGraph

    @State
    var cameraRotation = RollPitchYaw()

    init() {
        let device = MTLCreateSystemDefaultDevice()!
        let scene = try! SceneGraph.demo(device: device)
        self.device = device
        self.scene = scene
    }

    public var body: some View {
        RenderView(renderPasses: [
            DiffuseShadingRenderPass(scene: scene),
            DebugRenderPass(scene: scene),
            UnlitShadingPass(scene: scene),
        ])
        .onChange(of: cameraRotation) {
            scene.currentCameraNode?.transform.rotation = .rollPitchYaw(cameraRotation)
        }
        .renderContext(try! .init(device: device))
        .ballRotation($cameraRotation)
    }
}

extension SceneGraph {
    static func demo(device: MTLDevice) throws -> SceneGraph {
        let sphere = try Sphere3D(radius: 0.25).toMTKMesh(device: device)
        let cylinder = try Cylinder3D(radius: 0.25, height: 0.5).toMTKMesh(allocator: nil, device: device)

        // TODO: this is ugly
        let converter = Sphere3D.MDLMeshConverter(inwardNormals: true, allocator: MTKMeshBufferAllocator(device: device))
        let panorama = Sphere3D(radius: 400)
        let panoramaMesh = try MTKMesh(mesh: try converter.convert(panorama), device: device)
        let loader = MTKTextureLoader(device: device)
        let texture = try loader.newTexture(name: "BlueSkySkybox", scaleFactor: 2, bundle: Bundle.module)

        // TODO: Pano location should always be tied to camera location


        return SceneGraph(root:
            Node(label: "root", children: [
                Node(label: "camera", transform: .translation([0, 0, 5]), content: .camera(PerspectiveCamera()), children: [
                    Node(label: "pano", transform: .translation([0, 0, 0]), content: .geometry(.init(mesh: panoramaMesh, materials: [UnlitMaterialX(baseColorFactor: [1, 1, 0, 1], baseColorTexture: texture)]))),
                ]),
                Node(label: "model-1", transform: .translation([-0.5, 0, 0]), content: .geometry(.init(mesh: sphere, materials: [DiffuseShadingRenderPass.Material(diffuseColor: .red, ambientColor: CGColor(gray: 0, alpha: 1))]))),
                Node(label: "model-2", transform: .translation([0.5, 0, 0]), content: .geometry(.init(mesh: cylinder, materials: [DiffuseShadingRenderPass.Material(diffuseColor: .green, ambientColor: CGColor(gray: 0, alpha: 1))]))),
                Node(label: "model-3", transform: .translation([1.5, 0, 0]), content: .geometry(.init(mesh: sphere, materials: [UnlitMaterialX(baseColorFactor: [1, 1, 0, 1])]))),

            ])
        )
    }
}
