import CoreGraphicsSupport
import Metal
import MetalKit
import MetalSupport
import RenderKit
import RenderKitShaders
import Shapes3D
import SIMDSupport
import SwiftGLTF
import SwiftGraphicsSupport
import SwiftUI

// swiftlint:disable force_try

public struct SimplePBRSceneGraphDemoView: View, DemoView {
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

    public var body: some View {
        RenderView(device: device, passes: [
            DiffuseShadingRenderPass(scene: scene),
            UnlitShadingPass(scene: scene),
            SimplePBRShadingPass(scene: scene),
            //            DebugRenderPass(scene: scene),
        ])
        .showFrameEditor()
        .onChange(of: cameraRotation, initial: true) {
            let b = BallConstraint(radius: 5, rollPitchYaw: cameraRotation)
            scene.currentCameraNode?.transform = b.transform
        }
        .ballRotation($cameraRotation)
        .inspector(isPresented: .constant(true)) {
            let path = scene.root.allIndexedNodes().first { $0.0.label == "model-1" }!.1
            let material = Binding<SimplePBRMaterial> {
                guard let material = scene.root[indexPath: path].content!.geometry!.materials[0] as? SimplePBRMaterial else {
                    fatalError()
                }
                return material
            }
            set: {
                print("SET MATERIAL: \($0)")
                scene.root[indexPath: path].content!.geometry!.materials[0] = $0
            }
            SimplePBRMaterialEditor(material: material)
        }
        .onChange(of: scene) {
            print("Scene did change")
        }
    }
}

// func loadit() throws {
//    let url = Bundle.module.url(forResource: "Models/BarramundiFish", withExtension: "glb")!
//    let fish = try GLB(url: url)
//    let document = try fish.document()
//    guard let scene = try document.scene?.resolve(in: document) else {
//        fatalError()
//    }
//    guard let node = try scene.nodes.first?.resolve(in: document) else {
//        fatalError()
//    }
//    print(node)
//    guard let mesh = try node.mesh?.resolve(in: document) else {
//        fatalError()
//    }
//    print(mesh)
// }

extension SceneGraph {
    static func pbrDemo(device: MTLDevice) throws -> SceneGraph {
        let sphere = try Sphere3D(radius: 1.5).toMTKMesh(device: device, segments: [96, 96])
        let panoramaMesh = try Sphere3D(radius: 400).toMTKMesh(device: device, inwardNormals: true)
        let loader = MTKTextureLoader(device: device)
        let panoramaTexture = try loader.newTexture(name: "BlueSkySkybox", scaleFactor: 2, bundle: Bundle.module)
        let grassTexture = try loader.newTexture(name: "grass_teal_block_256x", scaleFactor: 2, bundle: Bundle.module)

        let quad = try Quad<SimpleVertex>(x: -0.5, y: -0.5, width: 1, height: 1).toMTKMesh(device: device)

        return try SceneGraph(root:
                                Node(label: "root") {
            Node(label: "camera")
                .content(.camera(Camera()))
                .transform(translation: [0, 0, 5])
                .children {
                    // TODO: Pano location should always be tied to camera location
                    Node(label: "pano")
                        .content(.geometry(mesh: panoramaMesh, materials: [UnlitMaterialX(baseColorTexture: panoramaTexture)]))
                }
            Node(label: "model-1")
                .content(.geometry(mesh: sphere, materials: [SimplePBRMaterial(baseColor: [1, 0, 0], metallic: 0.5, roughness: 0.5)]))
            Node(label: "model-2")
                .content(.geometry(mesh: quad, materials: [UnlitMaterialX(baseColorTexture: grassTexture)]))
                .transform(scale: [10, 10, 10])
                .transform(.init(rotation: .rotation(angle: .degrees(90), axis: [1, 0, 0])))
                .transform(translation: [0, -1, 0])
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

public struct SimplePBRShadingPass: RenderPassProtocol {
    public struct State: PassState {
        var renderPipelineState: MTLRenderPipelineState
        var depthStencilState: MTLDepthStencilState

        struct Bindings {
            var vertexBufferIndex: Int
            var vertexUniformsIndex: Int
            var fragmentUniformsIndex: Int
            var fragmentMaterialIndex: Int
            var fragmentLightIndex: Int
        }
        var bindings: Bindings
    }

    public var id: AnyHashable = "SimplePBRShadingPass"
    public var scene: SceneGraph

    public init(scene: SceneGraph) {
        self.scene = scene
    }

    public func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .renderKitShaders)
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "SimplePBRShader::VertexShader")!
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "SimplePBRShader::FragmentShader")!
        let depthStencilDescriptor = MTLDepthStencilDescriptor(depthCompareFunction: .less, isDepthWriteEnabled: true)
        let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).safelyUnwrap(RenderKitError.generic("Could not create depth stencil state"))
        renderPipelineDescriptor.label = "\(type(of: self))"

        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(oneTrueVertexDescriptor)

        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
        guard let reflection else {
            fatalError("No reflection for render pipeline.")
        }
        let bindings = State.Bindings(
            vertexBufferIndex: try reflection.binding(for: "vertexBuffer.0", of: .vertex),
            vertexUniformsIndex: try reflection.binding(for: "uniforms", of: .vertex),
            fragmentUniformsIndex: try reflection.binding(for: "uniforms", of: .fragment),
            fragmentMaterialIndex: try reflection.binding(for: "material", of: .fragment),
            fragmentLightIndex: try reflection.binding(for: "light", of: .fragment)
        )

        return State(renderPipelineState: renderPipelineState, depthStencilState: depthStencilState, bindings: bindings)
    }

    public func encode(device: MTLDevice, state: inout State, drawableSize: SIMD2<Float>, commandEncoder: any MTLRenderCommandEncoder) throws {
        let helper = try SceneGraphRenderHelper(scene: scene, drawableSize: drawableSize)
        let elements = helper.elements(material: SimplePBRMaterial.self)
        commandEncoder.setDepthStencilState(state.depthStencilState)
        commandEncoder.setRenderPipelineState(state.renderPipelineState)
        let bindings = state.bindings
        for element in elements {
            guard let material = element.material else {
                fatalError()
            }
            commandEncoder.withDebugGroup("Node: \(element.node.id)") {
                commandEncoder.withDebugGroup("VertexShader") {
                    let uniforms = SimplePBRVertexUniforms(
                        modelViewProjectionMatrix: element.modelViewProjectionMatrix,
                        modelMatrix: element.modelMatrix
                    )
                    commandEncoder.setVertexBytes(of: uniforms, index: bindings.vertexUniformsIndex)
                }

                commandEncoder.withDebugGroup("FragmentShader") {
                    //                    let vertexBuffer = element.geometry.mesh.vertexBuffers[0]
                    //                    commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: bindings.vertexBufferIndex)

                    let uniforms = SimplePBRFragmentUniforms(cameraPosition: helper.scene.currentCameraNode!.transform.translation)
                    commandEncoder.setFragmentBytes(of: uniforms, index: bindings.fragmentUniformsIndex)

                    commandEncoder.setFragmentBytes(of: material, index: bindings.fragmentMaterialIndex)

                    let light = SimplePBRLight(position: [0, 0, 2], color: [1, 1, 1], intensity: 1)
                    commandEncoder.setFragmentBytes(of: light, index: bindings.fragmentLightIndex)

                    //                    if let texture = material.baseColorTexture {
                    //                        commandEncoder.setFragmentBytes(of: UnlitMaterial(color: material.baseColorFactor, textureIndex: 0), index: bindings.fragmentMaterialsIndex)
                    //                        commandEncoder.setFragmentTextures([texture], range: 0..<(bindings.fragmentTexturesIndex + 1))
                    //                    }
                }

                assert(element.geometry.mesh.vertexBuffers.count == 1)
                commandEncoder.draw(element.geometry.mesh)
            }
        }
    }
}
