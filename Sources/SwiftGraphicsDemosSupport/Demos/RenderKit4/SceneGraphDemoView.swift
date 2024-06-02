import Metal
import RenderKit4
import Shapes3D
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI

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
            SimpleShadingRenderPass(scene: scene),
            DebugRenderPass(scene: scene),
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
        let cylinder = try Cylinder3D(radius: 1, depth: 1).toMTKMesh(allocator: nil, device: device)

        return SceneGraph(root:
            Node(label: "root", children: [
                Node(label: "camera", transform: .translation([0, 0, 5]), content: .camera(PerspectiveCamera())),
                Node(label: "sphere", transform: .translation([-0.5, 0, 0]), content: .geometry(.init(mesh: sphere, materials: [SimpleShadingRenderPass.Material(diffuseColor: .green, ambientColor: CGColor(gray: 0, alpha: 1))]))),
                Node(label: "sphere", transform: .translation([0.5, 0, 0]), content: .geometry(.init(mesh: sphere, materials: [SimpleShadingRenderPass.Material(diffuseColor: .red, ambientColor: CGColor(gray: 0, alpha: 1))]))),
//                Node(label: "cylinder", transform: .translation([0.5, 0, 0]), content: .geometry(.init(mesh: cylinder, materials: [SimpleShadingRenderPass.Material(diffuseColor: .red, ambientColor: CGColor(gray: 0, alpha: 1))]))),
            ])
        )
    }
}
