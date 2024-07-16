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

public struct GaussianSplatView: View {
    @State
    private var device: MTLDevice

    @State
    private var scene: SceneGraph

    @State
    private var isTargeted = false

    @State
    private var debugMode: Bool = false

    @State
    private var sortRate: Int = 8

    @State
    private var ballConstraint = BallConstraint()

    public init() {
        let device = MTLCreateSystemDefaultDevice()!
        let url = Bundle.module.url(forResource: "train", withExtension: "splat")!
        self.device = device
        let splats = try! SplatCloud(device: device, url: url)
        let root = Node(label: "root") {
            Node(label: "ball") {
                Node(label: "camera")
                    // .transform(translation: [0, 0, 04])
                    .content(Camera())
            }
            Node(label: "splats").content(splats)
        }
        self.scene = SceneGraph(root: root)
    }

    @State
    private var more = false

    public var body: some View {
        GaussianSplatRenderView(scene: scene, debugMode: debugMode, sortRate: sortRate, metalFXRate: 1)
            .toolbar {
                Button("More") {
                    more = true
                }
                .sheet(isPresented: $more) {
                    OptionsView(scene: $scene, debugMode: $debugMode, sortRate: $sortRate)
                }
            }
            .modifier(SceneGraphViewModifier(scene: $scene))
            .onDrop(of: [.splat], isTargeted: $isTargeted) { items in
                if let item = items.first {
                    item.loadItem(forTypeIdentifier: UTType.splat.identifier, options: nil) { data, _ in
                        guard let url = data as? URL else {
                            fatalError("No url")
                            return
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
    }
}

struct OptionsView: View {
    @Environment(\.dismiss)
    var dismiss

    @Environment(\.metalDevice)
    var device

    @Binding
    var scene: SceneGraph

    @State
    private var bitsPerPositionScalar = 16

    @Binding
    var debugMode: Bool

    @Binding
    var sortRate: Int

    var body: some View {
        VStack {
            Form {
                Text("#splats: \(scene.splatsNode.splats?.splats.count ?? 0)")
                Toggle("Debug Mode", isOn: $debugMode)
                HStack {
                    Slider(value: $sortRate.toDouble, in: 1 ... 60) { Text("Sort Rate") }
                        .frame(maxWidth: 120)
                    Text("\(sortRate)")
                }
                Button("Flip") {
                    scene.splatsNode.transform.rotation.rollPitchYaw.roll += .degrees(180)
                }
                TextField("Bits per position scalar", value: $bitsPerPositionScalar, format: .number)

                ValueView(value: false) { isPresented in
                    Toggle("Load…", isOn: isPresented)
                        .fileImporter(isPresented: isPresented, allowedContentTypes: [.splatC, .splat]) { result in
                            if case let .success(url) = result {
                                scene.splatsNode.content = try! SplatCloud(device: device, url: url, bitsPerPositionScalar: bitsPerPositionScalar)
                            }
                        }
                        .toggleStyle(.button)
                }
                HStack {
                    ForEach(try! Bundle.module.urls(withExtension: "splat"), id: \.self) { url in
                        Button(url.lastPathComponent) {
                            scene.splatsNode.content = try! SplatCloud(device: device, url: url)
                        }
                    }
                    ForEach(try! Bundle.module.urls(withExtension: "splatc"), id: \.self) { url in
                        Button(url.lastPathComponent) {
                            scene.splatsNode.content = try! SplatCloud(device: device, url: url)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("OK") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
}
