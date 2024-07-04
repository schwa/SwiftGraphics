import CoreGraphicsSupport
import Everything
import Foundation
import GaussianSplatSupport
import MetalKit
import MetalSupport
import Observation
import RenderKit
import RenderKitSupport
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI
import UniformTypeIdentifiers

// swiftlint:disable force_try

public struct GaussianSplatView: View {
    @State
    private var device: MTLDevice

    @State
    private var viewModel = GaussianSplatViewModel()

    @State
    private var size: CGSize = .zero

    @Environment(\.displayScale)
    var displayScale

    @State
    private var drawableSize: SIMD2<Float>?

    @State
    private var updatesPitch: Bool = true

    @State
    private var updatesYaw: Bool = true

    @State
    private var scene: SceneGraph

    public init() {
        let device = MTLCreateSystemDefaultDevice()!
        let url = Bundle.module.url(forResource: "train", withExtension: "splatc")!
        self.device = device
        let splats = try! Splats<SplatC>(device: device, url: url)
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

    public var body: some View {
        GaussianSplatRenderView(device: device, scene: scene)
            .environment(viewModel)
            .overlay(alignment: .bottom) {
                VStack {
                    Text("Size: [\(size * displayScale, format: .size)]")
                    Text("#splats: \(scene.splatsNode.splats?.splats.count ?? 0)")
                    HStack {
                        Slider(value: $scene.currentCameraNode.unsafeBinding().transform.translation.z, in: 0.0 ... 20.0) { Text("Distance") }
                            .frame(maxWidth: 120)
                        TextField("Distance", value: $scene.currentCameraNode.unsafeBinding().transform.translation.z, format: .number)
                            .labelsHidden()
                            .frame(maxWidth: 120)
                    }
                    Toggle("Debug Mode", isOn: $viewModel.debugMode)
                    HStack {
                        Slider(value: $viewModel.sortRate.toDouble, in: 1 ... 60) { Text("Sort Rate") }
                            .frame(maxWidth: 120)
                        Text("\(viewModel.sortRate)")
                    }
                }
                .padding()
                .background(.ultraThickMaterial).cornerRadius(8)
                .padding()
            }
            .toolbar {
                Button("Flip") {
                    scene.splatsNode.transform.rotation.rollPitchYaw.roll += .degrees(180)
                }
                ValueView(value: false) { isPresented in
                    Toggle("Load", isOn: isPresented)
                        .fileImporter(isPresented: isPresented, allowedContentTypes: [.splatC, .splat]) { result in
                            if case let .success(url) = result {
                                scene.splatsNode.content = try! Splats<SplatC>(device: device, url: url)
                            }
                        }
                }
                ForEach(try! Bundle.module.urls(withExtension: "splatc"), id: \.self) { url in
                    Button(url.lastPathComponent) {
                        scene.splatsNode.content = try! Splats<SplatC>(device: device, url: url)
                    }
                }
            }
            .modifier(SceneGraphViewModifier(device: device, scene: $scene, passes: []))
    }
}

extension SceneGraph {
    var splatsNode: Node {
        get {
            node(for: "splats")!
        }
        set {
            let accessor = accessor(for: "splats")!
            self[accessor: accessor] = newValue
        }
    }
}

extension Node {
    var splats: Splats<SplatC>? {
        content as? Splats<SplatC>
    }
}

extension Splats where Splat == SplatC {
    init(device: MTLDevice, url: URL) throws {
        let data = try Data(contentsOf: url)
        let splats: TypedMTLBuffer<SplatC>
        if url.pathExtension == "splatc" {
            splats = try device.makeTypedBuffer(data: data, options: .storageModeShared).labelled("Splats")
        }
        else if url.pathExtension == "splat" {
            let splatArray = data.withUnsafeBytes { buffer in
                buffer.withMemoryRebound(to: SplatB.self) { buffer in
                    convert(buffer)
                }
            }
            splats = try device.makeTypedBuffer(data: splatArray, options: .storageModeShared).labelled("Splats")
        }
        else {
            fatalError()
        }
        self = try Splats<SplatC>(device: device, splats: splats)
    }
}

extension UTType {
    static let splat = UTType(filenameExtension: "splat")!
    static let splatC = UTType(filenameExtension: "splatc")!
}

extension Splats: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        "Splats()"
    }
}
