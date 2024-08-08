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

    public init() {
        let device = MTLCreateSystemDefaultDevice()!
        let url = Bundle.module.url(forResource: "vision_dr", withExtension: "splat")!
        let splats = try! SplatCloud<SplatC>(device: device, url: url)
        let root = Node(label: "root") {
            Node(label: "ball") {
                Node(label: "camera", content: Camera())
            }
            Node(label: "splats").content(splats)
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
            .modifier(NewBallControllerViewModifier(constraint: .init(radius: 5), transform: $scene.unsafeCurrentCameraNode.transform))
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

struct ZoomGestureViewModifier: ViewModifier {
    @Binding
    var zoom: Float

    var range: ClosedRange<Float>

    @State
    var initialZoom: Float?

    init(zoom: Binding<Float>, range: ClosedRange<Float>) {
        self._zoom = zoom
        self.range = range
    }

    func body(content: Content) -> some View {
        content
            .gesture(magnifyGesture)
    }

    func magnifyGesture() -> some Gesture {
        MagnifyGesture()
            .onEnded { _ in
                initialZoom = nil
            }
            .onChanged { value in
                if initialZoom == nil {
                    initialZoom = zoom
                }
                guard let initialZoom else {
                    fatalError("Cannot zoom without an initial zoom value.")
                }
                zoom = clamp(initialZoom / Float(value.magnification), to: range)
            }
    }
}

extension View {
    func zoomGesture(zoom: Binding<Float>, range: ClosedRange<Float> = -.infinity ... .infinity) -> some View {
        modifier(ZoomGestureViewModifier(zoom: zoom, range: range))
    }
}
