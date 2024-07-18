import BaseSupport
import CoreGraphicsSupport
import Everything
import Foundation
import GaussianSplatSupport
import MetalKit
import MetalSupport
import Observation
import RenderKit
import RenderKitUISupport
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI
import UniformTypeIdentifiers

// swiftlint:disable force_unwrapping

public struct GaussianSplatMinimalView: View {
    @State
    private var device: MTLDevice

    @State
    private var scene: SceneGraph

    @State
    private var cameraRotation = RollPitchYaw()

    @State
    private var ballConstraint = BallConstraint(radius: 0.4)

    @State
    private var isTargeted = false

    @State
    private var metalFXRate: Float = 1

    public init() {
        let device = MTLCreateSystemDefaultDevice()!
        let url = Bundle.module.url(forResource: "winter_fountain", withExtension: "splat")!
        self.device = device
        let splats = try! SplatCloud(device: device, url: url)
        let root = Node(label: "root") {
            Node(label: "ball") {
                Node(label: "camera")
                    .content(Camera())
            }
            Node(label: "splats").content(splats)
        }
        self.scene = SceneGraph(root: root)
    }

    public var body: some View {
        GaussianSplatRenderView(scene: scene, debugMode: false, sortRate: 30, metalFXRate: metalFXRate)
            #if os(iOS)
            .ignoresSafeArea()
            #endif
            .onChange(of: cameraRotation, initial: true) {
                ballConstraint.rollPitchYaw = cameraRotation
            }
            .onChange(of: ballConstraint, initial: true) {
                scene.currentCameraNode?.transform = ballConstraint.transform
            }
            .ballRotation($cameraRotation, pitchLimit: .degrees(-.infinity) ... .degrees(.infinity))
            .zoomGesture(zoom: $ballConstraint.radius)
            .onDrop(of: [.splat], isTargeted: $isTargeted) { items in
                if let item = items.first {
                    item.loadItem(forTypeIdentifier: UTType.splat.identifier, options: nil) { data, _ in
                        guard let url = data as? URL else {
                            fatalError("No url")
                        }
                        Task {
                            await MainActor.run {
                                scene.splatsNode.content = try! SplatCloud(device: device, url: url)
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
                TextField("MetalFX Rate", value: $metalFXRate, format: .number)
                Slider(value: $metalFXRate, in: 1...16, step: 0.25)
                    .frame(width: 120)
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
