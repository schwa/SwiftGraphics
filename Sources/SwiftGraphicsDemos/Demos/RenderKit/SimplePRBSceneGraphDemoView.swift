import BaseSupport
import Constraints3D
@preconcurrency import Metal
import MetalKit
import MetalSupport
import RenderKit
import RenderKitSceneGraph
import RenderKitShaders
import Shapes3D
import SIMDSupport
import SwiftGLTF
import SwiftUI

struct SimplePBRSceneGraphDemoView: View, DemoView {
    let device: MTLDevice

    @State
    private var scene: SceneGraph

    @State
    private var cameraRotation = RollPitchYaw()

    init() {
        let device = MTLCreateSystemDefaultDevice()!
        let scene = try! SceneGraph.pbrDemo(device: device)
        self.device = device
        self.scene = scene
    }

    var body: some View {
        RenderView(passes: [
            DiffuseShadingRenderPass(id: "diffuse", scene: scene),
            UnlitShadingPass(id: "unlit", scene: scene),
            SimplePBRShadingPass(id: "pbr", scene: scene),
            //            DebugRenderPass(scene: scene),
        ])
        .showFrameEditor()
        .modifier(NewBallControllerViewModifier(constraint: .init(radius: 5), transform: $scene.unsafeCurrentCameraNode.transform))
        .inspector(isPresented: .constant(true)) {
            let path = scene.firstAccessor(label: "model-1")!
            let material = Binding<SimplePBRMaterial> {
                guard let geometry = scene.root[accessor: path].geometry else {
                    fatalError("Failed to get geometry.")
                }
                guard let material = geometry.materials[0] as? SimplePBRMaterial else {
                    fatalError("Failed to get material.")
                }
                return material
            }
            set: {
                scene.root[accessor: path].geometry?.materials[0] = $0
            }
            SimplePBRMaterialEditor(material: material)
        }
        .onChange(of: scene) {
        }
    }
}

extension SceneGraph {
    static func pbrDemo(device: MTLDevice) throws -> SceneGraph {
        let sphere = try Sphere3D(radius: 1.5).toMTKMesh(device: device, segments: [96, 96])
        let panoramaMesh = try Sphere3D(radius: 400).toMTKMesh(device: device, inwardNormals: true)
        let loader = MTKTextureLoader(device: device)
        let panoramaTexture = try loader.newTexture(name: "BlueSkySkybox", scaleFactor: 2, bundle: Bundle.module)
        let grassTexture = try loader.newTexture(name: "grass_teal_block_256x", scaleFactor: 2, bundle: Bundle.module)

        let quad = try Quad<SimpleVertex>(x: -0.5, y: -0.5, width: 1, height: 1).toMTKMesh(device: device)

        return SceneGraph(root:
                            Node(label: "root") {
                                Node(label: "camera", content: Camera()) {
                                    // TODO: Pano location should always be tied to camera location
                                    Node(label: "pano", content: Geometry(mesh: panoramaMesh, materials: [UnlitMaterialX(baseColorTexture: panoramaTexture)]))
                                }
                                .transformed(translation: [0, 0, 5])
                                Node(label: "model-1", content: Geometry(mesh: sphere, materials: [SimplePBRMaterial(baseColor: [1, 0, 0], metallic: 0.5, roughness: 0.5)]))
                                Node(label: "model-2", content: Geometry(mesh: quad, materials: [UnlitMaterialX(baseColorTexture: grassTexture)]))
                                    .transformed(scale: [10, 10, 10])
                                    .transformed(.init(rotation: .rotation(angle: .degrees(90), axis: [1, 0, 0])))
                                    .transformed(translation: [0, -1, 0])
                            }
        )
    }
}

struct SimplePBRMaterialEditor: View {
    @Binding
    var material: SimplePBRMaterial

    @State
    private var baseColor: Color

    init(material: Binding<SimplePBRMaterial>) {
        self._material = material
        self.baseColor = Color(
            red: Double(material.wrappedValue.baseColor[0]),
            green: Double(material.wrappedValue.baseColor[1]),
            blue: Double(material.wrappedValue.baseColor[2])
        )
    }

    var body: some View {
        Form {
            LabeledContent("Base Color") {
                ColorPicker("Base Color", selection: $baseColor)
            }
            LabeledContent("Metallic") {
                VStack {
                    TextField("Metallic", value: $material.metallic, format: .number)
                        .labelsHidden()
                    Slider(value: $material.metallic, in: 0...1)
                }
            }
            LabeledContent("Roughness") {
                VStack {
                    TextField("Roughness", value: $material.roughness, format: .number)
                        .labelsHidden()
                    Slider(value: $material.roughness, in: 0...1)
                }
            }
        }
        .onChange(of: baseColor) {
            let cgColor = baseColor.resolve(in: .init()).cgColor
            let components = cgColor.components!.map(Float.init)
            material.baseColor = [components[0], components[1], components[2]]
        }
    }
}

// MARK: -

extension SimplePBRLight: @retroactive LightProtocol, @retroactive @unchecked Sendable, @retroactive Equatable, UnsafeMemoryEquatable {
}

extension SimplePBRMaterial: @retroactive MaterialProtocol, @retroactive @unchecked Sendable, @retroactive Equatable, UnsafeMemoryEquatable {
}

// <ARL:
