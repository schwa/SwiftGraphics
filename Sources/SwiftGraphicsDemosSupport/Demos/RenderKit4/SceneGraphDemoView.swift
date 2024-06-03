import Metal
import RenderKit4
import Shapes3D
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI
import MetalKit
import MetalSupport
import CoreGraphicsSupport

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
        .toolbar {
            Button("Snapshot") {
                snapshot()
            }
        }
    }

    func snapshot() {
        Task {
            var renderer = try! OffscreenRenderer(size: [640, 480], device: device, renderPasses: [
                DiffuseShadingRenderPass(scene: scene),
//                DebugRenderPass(scene: scene),
    //            UnlitShadingPass(scene: scene),
            ])

            let colorAttachmentTexture = try OffscreenRenderer.makeColorTexture(device: device, size: renderer.size, pixelFormat: .bgra8Unorm)
            renderer.addColorAttachment(at: 0, texture: colorAttachmentTexture, clearColor: .init(red: 0, green: 0, blue: 0, alpha: 1))

            let depthAttachmentTexture = try OffscreenRenderer.makeDepthTexture(device: device, size: renderer.size, depthStencilPixelFormat: .depth32Float, memoryless: true)
            renderer.addDepthAttachment(texture: depthAttachmentTexture, clearDepth: 1)

            try! renderer.prepare()

            try! renderer.render(waitAfterCommit: true)
            let texture = renderer.colorAttachmentTexture(at: 0)!
            let image = texture.cgImage()!
            print(image)
            try! ImageDestination.write(image: image, to: URL(filePath: "test.png"))
        }

    }
}

extension SceneGraph {
    static func demo(device: MTLDevice) throws -> SceneGraph {
        let sphere = try Sphere3D(radius: 0.25).toMTKMesh(device: device)
        let cylinder = try Cylinder3D(radius: 0.25, height: 0.5).toMTKMesh(device: device)

        // TODO: this is ugly
        let panoramaMesh = try Sphere3D(radius: 400).toMTKMesh(device: device, inwardNormals: true)
        let loader = MTKTextureLoader(device: device)
        let panoramaTexture = try loader.newTexture(name: "BlueSkySkybox", scaleFactor: 2, bundle: Bundle.module)

        let quad = try Quad<SimpleVertex>(x: 0, y: 0, width: 1, height: 1).toMTKMesh(device: device)


        // TODO: Pano location should always be tied to camera location
        return SceneGraph(root:
            Node(label: "root", children: [
                Node(label: "camera", transform: .translation([0, 0, 5]), content: .camera(PerspectiveCamera()), children: [
                    Node(label: "pano", transform: .translation([0, 0, 0]), content: .geometry(.init(mesh: panoramaMesh, materials: [UnlitMaterialX(baseColorFactor: [1, 1, 0, 1], baseColorTexture: panoramaTexture)]))),
                ]),
                Node(label: "model-1", transform: .translation([-0.5, 0, 0]), content: .geometry(.init(mesh: sphere, materials: [DiffuseShadingRenderPass.Material(diffuseColor: .red, ambientColor: CGColor(gray: 0, alpha: 1))]))),
                Node(label: "model-2", transform: .translation([0.5, 0, 0]), content: .geometry(.init(mesh: cylinder, materials: [DiffuseShadingRenderPass.Material(diffuseColor: .green, ambientColor: CGColor(gray: 0, alpha: 1))]))),
                Node(label: "model-3", transform: .translation([1.5, 0, 0]), content: .geometry(.init(mesh: sphere, materials: [UnlitMaterialX(baseColorFactor: [1, 1, 0, 1])]))),
                Node(label: "model-4", transform: .translation([0, 0, 0]), content: .geometry(.init(mesh: quad, materials: [DiffuseShadingRenderPass.Material(diffuseColor: .red, ambientColor: CGColor(gray: 0, alpha: 1))]))),

            ])
        )
    }
}
