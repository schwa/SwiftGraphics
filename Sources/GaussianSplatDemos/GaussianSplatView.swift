import BaseSupport
import Constraints3D
import Everything
import Foundation
import GaussianSplatSupport
import MetalKit
import Observation
import RenderKit
import RenderKitSceneGraph
import RenderKitUISupport
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI
import UniformTypeIdentifiers
import SwiftUISupport

// swiftlint:disable force_unwrapping

public struct GaussianSplatView: View {
    @State
    private var device: MTLDevice

    @State
    private var scene: SceneGraph

    @State
    private var cameraRotation = RollPitchYaw()

    @State
    private var isTargeted = false

    @State
    private var metalFXRate: Float = 1

    @State
    private var gpuCounters: GPUCounters

    @State
    private var discardRate: Float = 0

    @State
    private var sortRate: Int = 15

    @State
    private var cameraCone: CameraCone = .init(apex: [0, 0, 0], axis: [0, 1, 0], h1: 0, r1: 0.5, r2: 0.75, h2: 0.5)

    enum Controller {
        case none
        case cone
        case fpv
        case ball
    }

    @State
    private var controller = Controller.cone

    @State
    private var ballConstraint: NewBallConstraint = .init(radius: 0.25)

    public init() {
        let device = MTLCreateSystemDefaultDevice()!
        let url = Bundle.module.url(forResource: "vision_dr", withExtension: "splat")!
        let splats = try! SplatCloud<SplatC>(device: device, url: url)
        let root = Node(label: "root") {
            Node(label: "camera", content: Camera())
            Node(label: "splats", content: splats).transformed(roll: .zero, pitch: .degrees(270), yaw: .zero).transformed(roll: .zero, pitch: .zero, yaw: .degrees(90)).transformed(translation: [0, 0.25, 0.5])
        }

        self.device = device
        self.scene = SceneGraph(root: root)
        self.gpuCounters = try! GPUCounters(device: device)
    }

    func performanceMeter() -> some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { _ in
            PerformanceHUD(measurements: gpuCounters.current())
        }
    }

    public var body: some View {
        GaussianSplatRenderView<SplatC>(scene: scene, debugMode: false, sortRate: sortRate, metalFXRate: metalFXRate, discardRate: discardRate)
            .overlay(alignment: .top) {
                performanceMeter()
            }
            .environment(\.gpuCounters, gpuCounters)
            #if os(iOS)
            .ignoresSafeArea()
            #endif
            .modifier {
                switch controller {
                case .none:
                    EmptyViewModifier()
                case .cone:
                    CameraConeController(cameraCone: cameraCone, transform: $scene.unsafeCurrentCameraNode.transform)
                case .fpv:
                    FirstPerson3DGameControllerViewModifier(transform: $scene.unsafeCurrentCameraNode.transform)
                case .ball:
                    NewBallControllerViewModifier(constraint: ballConstraint, transform: $scene.unsafeCurrentCameraNode.transform)
                }
            }
            .inspector(isPresented: .constant(true)) {
                Form {
                    Picker("Controller", selection: $controller) {
                        Text("None").tag(Controller.none)
                        Text("Ball").tag(Controller.ball)
                        Text("Cone").tag(Controller.cone)
                        Text("FPV").tag(Controller.fpv)
                    }

                    Section("Cone") {
                        TextField("Apex", value: $cameraCone.apex, format: .vector)
                        TextField("Axis", value: $cameraCone.axis, format: .vector)
                        TextField("H1", value: $cameraCone.h1, format: .number)
                        TextField("H2", value: $cameraCone.h2, format: .number)
                        TextField("R1", value: $cameraCone.r1, format: .number)
                        TextField("R2", value: $cameraCone.r2, format: .number)
                    }
                    .disabled(controller != .cone)
                    LabeledContent("Ball.Radius") {
                        TextField("Ball Radius", value: $ballConstraint.radius, format: .number)
                        Slider(value: $ballConstraint.radius, in: 0...10).frame(width: 120)
                    }
                }
            }
            .onDrop(of: [.splat], isTargeted: $isTargeted) { items in
                if let item = items.first {
                    item.loadItem(forTypeIdentifier: UTType.splat.identifier, options: nil) { data, _ in
                        guard let url = data as? URL else {
                            fatalError("No url")
                        }
                        Task {
                            await MainActor.run {
                                scene.splatsNode.content = try! SplatCloud<SplatC>(device: device, url: url)
                            }
                        }
                    }
                    return true
                } else {
                    return false
                }
            }
            .border(isTargeted ? Color.accentColor : .clear, width: isTargeted ? 4 : 0)
            .toolbar {
                ValueView(value: false) { isPresented in
                    Toggle(isOn: isPresented) { Text("Sort Rate") }
                        .popover(isPresented: isPresented) {
                            Form {
                                TextField("Sort Rate", value: $sortRate, format: .number)
                                Slider(value: $sortRate.toDouble, in: 0...30)
                                    .frame(width: 120)
                            }
                            .padding()
                        }
                }

                ValueView(value: false) { isPresented in
                    Toggle(isOn: isPresented) { Text("MetalFX Factor") }
                        .popover(isPresented: isPresented) {
                            Form {
                                TextField("MetalFX Factor", value: $metalFXRate, format: .number)
                                Slider(value: $metalFXRate, in: 1...16)
                                    .frame(width: 120)
                            }
                            .padding()
                        }
                }

                ValueView(value: false) { isPresented in
                    Toggle(isOn: isPresented) { Text("Discard Rate") }
                        .popover(isPresented: isPresented) {
                            Form {
                                TextField("Discard Rate", value: $discardRate, format: .number)
                                Slider(value: $discardRate, in: 0 ... 1)
                                    .frame(width: 120)
                            }
                            .padding()
                        }
                }
            }
    }
}
