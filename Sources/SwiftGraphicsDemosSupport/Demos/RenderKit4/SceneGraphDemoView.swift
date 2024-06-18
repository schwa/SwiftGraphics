import CoreGraphicsSupport
import Metal
import MetalKit
import MetalSupport
import RenderKit
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
        let cameraNode = Binding<Node> {
            scene.currentCameraNode ?? Node()
        }
        set: { newValue in
            scene.currentCameraNode = newValue
        }

        RenderView(device: device, renderPasses: [
            DiffuseShadingRenderPass(scene: scene),
            UnlitShadingPass(scene: scene),
            DebugRenderPass(scene: scene),
        ])
//        .firstPersonInteractive(camera: cameraNode)
//        .displayLink(DisplayLink2())
        .showFrameEditor()
        .onChange(of: cameraRotation, initial: true) {
            //            scene.currentCameraNode?.transform.rotation = .rollPitchYaw(cameraRotation)

            let b = BallConstraint(radius: 5, rollPitchYaw: cameraRotation)
            scene.currentCameraNode?.transform = b.transform
        }
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
//                DiffuseShadingRenderPass(scene: scene),
//                DebugRenderPass(scene: scene),
                UnlitShadingPass(scene: scene),
            ])

            let colorAttachmentTexture = try device.makeColorTexture(size: renderer.size, pixelFormat: .bgra8Unorm)
            renderer.addColorAttachment(at: 0, texture: colorAttachmentTexture, clearColor: .init(red: 0, green: 0, blue: 0, alpha: 1))

            let depthAttachmentTexture = try device.makeDepthTexture(size: renderer.size, depthStencilPixelFormat: .depth32Float, memoryless: true)
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

#Preview {
    SceneGraphDemoView()
}
