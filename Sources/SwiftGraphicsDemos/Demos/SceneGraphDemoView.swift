import Metal
import MetalKit
import MetalSupport
import RenderKit
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
        //        TimelineView(.animation) { timeline in
        SceneGraphView(scene: $scene, passes: [
            DiffuseShadingRenderPass(scene: scene),
            UnlitShadingPass(scene: scene),
            DebugRenderPass(scene: scene),
        ])
        //            .onChange(of: timeline.date) {
        //                scene.modify(label: "model-1") { node in
        //                    node?.transform.rotation.rollPitchYaw.roll = .degrees((timeline.date.timeIntervalSince1970 * 30).wrapped(to: 0...360))
        //                }
        //                scene.modify(label: "model-2") { node in
        //                    node?.transform.rotation.rollPitchYaw.pitch = .degrees((timeline.date.timeIntervalSince1970 * 30).wrapped(to: 0...360))
        //                }
        //                scene.modify(label: "model-3") { node in
        //                    node?.transform.rotation.rollPitchYaw.yaw = .degrees((timeline.date.timeIntervalSince1970 * 30).wrapped(to: 0...360))
        //                }
        //            }
        //        }
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
                                        .content(Geometry(mesh: sphere, materials: [DiffuseShadingRenderPass.Material(diffuseColor: .red)]))
                                        .transform(translation: [-1, 0, 0])
                                    Node(label: "model-2")
                                        .content(Geometry(mesh: cylinder, materials: [DiffuseShadingRenderPass.Material(diffuseColor: .green)]))
                                        .transform(translation: [0, 0, 0])
                                    Node(label: "model-3")
                                        .content(Geometry(mesh: cone, materials: [DiffuseShadingRenderPass.Material(diffuseColor: .blue)]))
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
