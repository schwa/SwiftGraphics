import BaseSupport
import Constraints3D
import Everything
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
import Widgets3D

public struct SingleSplatView: View {
    @State
    private var viewModel: GaussianSplatViewModel

    @State
    private var modelTransform: Transform = .init(scale: [1, 1, 1])

    @State
    private var device: MTLDevice

    @State
    private var splat: SplatD

    @Environment(\.logger)
    var logger

    public init() {
        let device = MTLCreateSystemDefaultDevice()!
        let splat = SplatD(position: [0, 0, 0], scale: [1, 0.5, 0.25], color: [1, 0, 1, 1], rotation: .init(angle: .zero, axis: [0, 0, 0]))
        self.device = device
        self.splat = splat

        let splats = [splat].map(SplatC.init)
        let splatCloud = try! SplatCloud(device: device, splats: splats)

        self.viewModel = try! GaussianSplatViewModel(device: device, splatCloud: splatCloud, configuration: .init())
    }

    public var body: some View {
        GaussianSplatRenderView()
            .modifier(NewBallControllerViewModifier(constraint: .init(radius: 5), transform: $viewModel.scene.unsafeCurrentCameraNode.transform))
            .environment(viewModel)
            .onChange(of: splat, initial: true) {
                print("**** Splat changed ****")
                try! viewModel.scene.modify(label: "splats") { node in
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
                        RotationWidget(rotation: $viewModel.scene.splatsNode.transform.rotation)
                            .frame(width: 100, height: 100)
                            .padding()

                        axisEditor(label: "Roll", value: $viewModel.scene.splatsNode.transform.rotation.rollPitchYaw.roll)
                        axisEditor(label: "Pitch", value: $viewModel.scene.splatsNode.transform.rotation.rollPitchYaw.pitch)
                        axisEditor(label: "Yaw", value: $viewModel.scene.splatsNode.transform.rotation.rollPitchYaw.yaw)
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
                    TransformEditor($viewModel.scene.unsafeCurrentCameraNode.transform)
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
}
