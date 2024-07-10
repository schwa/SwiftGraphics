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

// swiftlint:disable force_try

public struct GaussianSplatView: View {
    @State
    private var device: MTLDevice

    @State
    private var viewModel = GaussianSplatViewModel()

    @State
    private var scene: SceneGraph

    public init() {
        let device = MTLCreateSystemDefaultDevice()!
        //        let url = Bundle.module.url(forResource: "6_20_2024", withExtension: "splatc")!
        let url = Bundle.module.url(forResource: "winter_fountain", withExtension: "splat")!
        self.device = device
        let splats = try! Splats(device: device, url: url)
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
        GaussianSplatRenderView(device: device, scene: scene)
            .toolbar {
                Button("More") {
                    more = true
                }
                .sheet(isPresented: $more) {
                    OptionsView(scene: $scene, device: device)
                }
            }
            .modifier(SceneGraphViewModifier(device: device, scene: $scene, passes: []))
            .environment(viewModel)
    }
}

struct OptionsView: View {
    @Environment(\.dismiss)
    var dismiss

    @Binding
    var scene: SceneGraph

    @Environment(GaussianSplatViewModel.self)
    private var viewModel

    var device: MTLDevice

    var body: some View {
        VStack {
            Form {
                @Bindable
                var viewModel = viewModel

                Text("#splats: \(scene.splatsNode.splats?.splats.count ?? 0)")
                Toggle("Debug Mode", isOn: $viewModel.debugMode)
                HStack {
                    Slider(value: $viewModel.sortRate.toDouble, in: 1 ... 60) { Text("Sort Rate") }
                        .frame(maxWidth: 120)
                    Text("\(viewModel.sortRate)")
                }
                Button("Flip") {
                    scene.splatsNode.transform.rotation.rollPitchYaw.roll += .degrees(180)
                }
                ValueView(value: false) { isPresented in
                    Toggle("Load…", isOn: isPresented)
                        .fileImporter(isPresented: isPresented, allowedContentTypes: [.splatC, .splat]) { result in
                            if case let .success(url) = result {
                                scene.splatsNode.content = try! Splats(device: device, url: url)
                            }
                        }
                        .toggleStyle(.button)
                }
                HStack {
                    ForEach(try! Bundle.module.urls(withExtension: "splat"), id: \.self) { url in
                        Button(url.lastPathComponent) {
                            scene.splatsNode.content = try! Splats(device: device, url: url)
                        }
                    }
                    ForEach(try! Bundle.module.urls(withExtension: "splatc"), id: \.self) { url in
                        Button(url.lastPathComponent) {
                            scene.splatsNode.content = try! Splats(device: device, url: url)
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
