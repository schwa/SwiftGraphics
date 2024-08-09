import BaseSupport
import Constraints3D
import Everything
import Fields3D
import GaussianSplatShaders
import GaussianSplatSupport
@preconcurrency import Metal
@preconcurrency import MetalKit
import MetalSupport
import Observation
import RenderKit
import RenderKitSceneGraph
import RenderKitUISupport
import simd
import SIMDSupport
import SwiftFields
import SwiftUI
import UniformTypeIdentifiers

public struct SingleSplatView: View {
    @State
    private var cameraTransform: Transform = .translation([0, 0, 5])

    @State
    private var cameraProjection: Projection = .perspective(.init())

    @State
    private var modelTransform: Transform = .init(scale: [1, 1, 1])

    @State
    private var device: MTLDevice

    @State
    private var splat: SplatD

    @State
    private var scene: SceneGraph

    public init() {
        let device = MTLCreateSystemDefaultDevice()!
        let splat = SplatD(position: [0, 0, 0], scale: [1, 0.5, 0.25], color: [1, 0, 1, 1], rotation: .init(angle: .zero, axis: [0, 0, 0]))
        self.device = device
        self.splat = splat
        let root = Node(label: "root") {
            Node(label: "camera", content: Camera())
            Node(label: "splats")
        }
        self.scene = SceneGraph(root: root)
    }

    public var body: some View {
        GaussianSplatRenderView<SplatC>(scene: scene)
            .modifier(CameraConeController(cameraCone: .init(apex: [0, 0, 0], axis: [0, 1, 0], apexToTopBase: 0, topBaseRadius: 2, bottomBaseRadius: 2, height: 2), transform: $scene.unsafeCurrentCameraNode.transform))
            .onChange(of: splat, initial: true) {
                try! scene.modify(label: "splats") { node in
                    let splats = [splat].map(SplatC.init)
                    node!.content = try SplatCloud(device: device, splats: splats)
                }
            }
            .inspector(isPresented: .constant(true)) {
                makeInspector()
            }
    }

    func axisEditor(label: String, value: Binding<Angle>) -> some View {
        LabeledContent(label) {
            Wheel(value: value.projectedValue.degrees, rate: 30)
            TextField(label, value: value.projectedValue.degrees, format: .number)
                .monospacedDigit()
                .frame(width: 80)
                .labelsHidden()
        }
    }

    @ViewBuilder
    func makeInspector() -> some View {
        Form {
            ValueView(value: true) { expanded in
                DisclosureGroup("Model Transform", isExpanded: expanded) {
                    VStack {
                        RotationWidget(rotation: $scene.splatsNode.transform.rotation)
                            .frame(width: 100, height: 100)
                            .padding()

                        axisEditor(label: "Roll", value: $scene.splatsNode.transform.rotation.rollPitchYaw.roll)
                        axisEditor(label: "Pitch", value: $scene.splatsNode.transform.rotation.rollPitchYaw.pitch)
                        axisEditor(label: "Yaw", value: $scene.splatsNode.transform.rotation.rollPitchYaw.yaw)

                        //                    TransformEditor($scene.splatsNode.transform)
                    }
                }
            }

            ValueView(value: false) { isPresented in
                ValueView(value: Optional<Data>.none) { data in
                    Button("Save Splat") {
                        let splats = [splat].map(SplatB.init)
                        splats.withUnsafeBytes { buffer in
                            data.wrappedValue = Data(buffer)
                        }
                        isPresented.wrappedValue = true
                    }
                    .fileExporter(isPresented: isPresented, item: data.wrappedValue/*, contentTypes: [.splat]*/) { _ in
                    }
                }
            }
            ValueView(value: false) { expanded in
                DisclosureGroup("Camera Transform", isExpanded: expanded) {
                    TransformEditor($cameraTransform)
                }
            }
            ValueView(value: true) { expanded in
                DisclosureGroup("Splat", isExpanded: expanded) {
                    Section("Splat Position") {
                        HStack {
                            TextField("X", value: $splat.position.x, format: .number)
                            TextField("Y", value: $splat.position.y, format: .number)
                            TextField("Z", value: $splat.position.z, format: .number)
                        }
                        .labelsHidden()
                    }
                    Section("Splat Scale") {
                        HStack {
                            TextField("X", value: $splat.scale.x, format: .number)
                            TextField("Y", value: $splat.scale.y, format: .number)
                            TextField("Z", value: $splat.scale.z, format: .number)
                        }
                        .labelsHidden()
                    }
                    Section("Splat Color") {
                        HStack {
                            TextField("R", value: $splat.color.x, format: .number)
                            TextField("G", value: $splat.color.y, format: .number)
                            TextField("B", value: $splat.color.z, format: .number)
                            TextField("A", value: $splat.color.w, format: .number)
                        }
                        .labelsHidden()
                    }
                    Section("Splat Rotation") {
                        RollPitchYawEditor($splat.rotation.rollPitchYaw)
                    }
                }
            }

            ValueView(value: false) { expanded in
                DisclosureGroup("Debug", isExpanded: expanded) {
                    Section("SplatB") {
                        Text("\(SplatB(splat))").monospaced()
                    }
                    Section("SplatC") {
                        Text("\(SplatC(splat))").monospaced()
                    }
                    Section("SplatD") {
                        Text("\(splat)").monospaced()
                    }
                }
            }
        }
    }

    func makeRandomSplats() -> [SplatD] {
        var randomSplats: [SplatD] = []
        for z: Float in stride(from: -1, through: 1, by: 1) {
            for y: Float in stride(from: -1, through: 1, by: 1) {
                for x: Float in stride(from: -1, through: 1, by: 1) {
                    //                    let color: SIMD4<Float> = [Float.random(in: 0 ... 1), Float.random(in: 0 ... 1), Float.random(in: 0 ... 1), 1]
                    var color: SIMD4<Float> = [1, 1, 1, 1]
                    if x == -1 {
                        color = [1, 0, 0, 1]
                    }
                    if x == 0 {
                        color = [0, 1, 0, 1]
                        if y == -1 {
                            color = [1, 1, 1, 1]
                        }
                    }
                    if x == 1 {
                        color = [0, 0, 1, 1]
                    }

                    let rotation = Rotation(.init(
                        roll: .degrees(Double(x) * 0),
                        pitch: .degrees(Double(y) * 0),
                        yaw: .degrees(Double(z) * 0)
                    ))

                    let randomSplat = SplatD(position: .init([x, y, z] + [1, 1, 1]), scale: .init([0.2, 0.0, 0.0]), color: color, rotation: rotation)
                    randomSplats.append(randomSplat)
                }
            }
        }
        return randomSplats
    }
}

struct SplatD: Equatable {
    var position: PackedFloat3
    var scale: PackedFloat3
    var color: SIMD4<Float>
    var rotation: Rotation
}

extension SplatB {
    init(_ other: SplatD) {
        let color = SIMD4<UInt8>(other.color * 255)
        let rotation_vector = other.rotation.quaternion.vectorRealFirst
        let rotation = ((rotation_vector / rotation_vector.length) * 128 + 128).clamped(to: 0...255)
        self = SplatB(position: other.position, scale: other.scale, color: color, rotation: SIMD4<UInt8>(rotation))
    }
}

extension SplatC {
    init(_ other: SplatD) {
        let transform = simd_float3x3(other.rotation.quaternion) * simd_float3x3(diagonal: SIMD3<Float>(other.scale))
        let cov3D = transform * transform.transpose
        let cov_a = PackedHalf3(x: Float16(cov3D[0, 0]), y: Float16(cov3D[0, 1]), z: Float16(cov3D[0, 2]))
        let cov_b = PackedHalf3(x: Float16(cov3D[1, 1]), y: Float16(cov3D[1, 2]), z: Float16(cov3D[2, 2]))

        self = SplatC(position: PackedHalf3(SIMD3<Float>(other.position)), color: PackedHalf4(other.color), cov_a: cov_a, cov_b: cov_b)
    }
}

extension simd_quatf {
    var vectorRealFirst: simd_float4 {
        [vector.w, vector.x, vector.y, vector.z]
    }
}
