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
        let cameraNode = Binding<Node> {
            return scene.currentCameraNode ?? Node()
        }
        set: { newValue in
            scene.currentCameraNode = newValue
        }

        RenderView(renderPasses: [
            DiffuseShadingRenderPass(scene: scene),
            UnlitShadingPass(scene: scene),
            DebugRenderPass(scene: scene),
        ])
        .firstPersonInteractive(camera: cameraNode)
        .displayLink(DisplayLink2())
        .showFrameEditor()
        .onChange(of: cameraRotation, initial: true) {
            //            scene.currentCameraNode?.transform.rotation = .rollPitchYaw(cameraRotation)

            let b = BallConstraint(radius: 5, lookAt: .zero, rollPitchYaw: cameraRotation)
            scene.currentCameraNode?.transform.matrix = b.transform
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
//                DiffuseShadingRenderPass(scene: scene),
//                DebugRenderPass(scene: scene),
                UnlitShadingPass(scene: scene),
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

#Preview {
    SceneGraphDemoView()
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

//        let x = try Quad<SimpleVertex>(x: 0, y: 0, width: 1, height: 1).toTrivialMesh()
//        x.dumpIndexedPositions()
//        try Cone3D(height: 1, radius: 0.5).write(to: URL(filePath: "test.obj"))

        return try SceneGraph(root:
            Node(label: "root") {
                Node(label: "camera")
                    .content(.camera(PerspectiveCamera()))
                    .transform(translation: [0, 0, 5])
                    .children {
                        // TODO: Pano location should always be tied to camera location
                        Node(label: "pano")
                        .content(.geometry(mesh: panoramaMesh, materials: [UnlitMaterialX(baseColorTexture: panoramaTexture)]))
                    }
                Node(label: "model-1")
                    .content(.geometry(mesh: sphere, materials: [DiffuseShadingRenderPass.Material(diffuseColor: .red)]))
                    .transform(translation: [-1, 0, 0])
                Node(label: "model-2")
                    .content(.geometry(mesh: cylinder, materials: [DiffuseShadingRenderPass.Material(diffuseColor: .green)]))
                    .transform(translation: [0, 0, 0])
                Node(label: "model-3")
                    .content(.geometry(mesh: cone, materials: [DiffuseShadingRenderPass.Material(diffuseColor: .blue)]))
                    .transform(translation: [1, 0, 0])
                    .transform(.init(rotation: .rotation(angle: .degrees(45) , axis: [1, 0, 0])))
                Node(label: "model-4")
                    .content(.geometry(mesh: quad, materials: [UnlitMaterialX(baseColorTexture: grassTexture)]))
                    .transform(scale: [10, 10, 10])
                    .transform(.init(rotation: .rotation(angle: .degrees(90) , axis: [1, 0, 0])))
                    .transform(translation: [0, -1, 0])
            }
        )
    }
}

extension Node {
    func transform(_ transform: Transform) -> Node {
        var copy = self
        if copy.transform == .identity {
            copy.transform = transform
        }
        else {
            copy.transform.matrix = transform.matrix * copy.transform.matrix
        }
        return copy
    }
    func transform(translation: SIMD3<Float>) -> Node {
        transform(.translation(translation))
    }
    func transform(scale: SIMD3<Float>) -> Node {
        transform(Transform(scale: scale))
    }
    func content(_ content: Content) -> Node {
        var copy = self
        copy.content = content
        return copy
    }
    func children(@NodeBuilder _  children: () -> [Node]) -> Node {
        var copy = self
        copy.children = children()
        return copy
    }
}

extension Node.Content {
    static func geometry(mesh: MTKMesh, materials: [any SG3MaterialProtocol]) -> Self {
        return .geometry(.init(mesh: mesh, materials: materials))
    }
}

//extension TrivialMesh where Vertex == SimpleVertex {
//    func dumpPositions() {
//        print(self.vertices.map(\.position).map({ "\($0, format: .vector)" }).joined(separator: ",\n"))
//    }
//
//    func dumpIndexedPositions() {
//        for index in indices {
//            let vertex = vertices[index]
//            print("#\(index): \(vertex.position, format: .vector)")
//        }
//    }
//
//}
//
//

extension Node: FirstPersonCameraProtocol {
    var target: SIMD3<Float> {
        get {
            .zero
        }
        set {
        }
    }

    var heading: Angle {
        get {
            .zero
        }
        set {
        }
    }


}
