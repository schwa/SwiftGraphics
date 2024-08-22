import BaseSupport
import Constraints3D
import CoreGraphicsUnsafeConformances
import Everything
import Foundation
import GaussianSplatSupport
import MetalKit
import Observation
import Projection
import RenderKit
import RenderKitSceneGraph
import RenderKitUISupport
import Shapes3D
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI
import SwiftUISupport
import UniformTypeIdentifiers

// swiftlint:disable force_unwrapping

public struct GaussianSplatLoadingView: View {
    @Environment(\.metalDevice)
    private var device

    let url: URL
    let configuration: GaussianSplatRenderingConfiguration
    let splatLimit: Int?

    @State
    private var subtitle: String = "Processing"

    @State
    private var splatCloud: SplatCloud<SplatC>?

    public init(url: URL, initialConfiguration: GaussianSplatRenderingConfiguration, splatLimit: Int?) {
        self.url = url
        self.configuration = initialConfiguration
        self.splatLimit = splatLimit
    }

    public var body: some View {
        ZStack {
            if let splatCloud {
                GaussianSplatNewMinimalView(splatCloud: splatCloud, configuration: configuration)
            }
            else {
                VStack {
                    ProgressView()
                    Text(subtitle)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            do {
                switch url.scheme {
                case "http", "https":
                    subtitle = "Downloading"
                    let request = URLRequest(url: url)
                    let (localURL, response) = try await URLSession.shared.download(for: request)
                    guard let response = response as? HTTPURLResponse else {
                        fatalError()
                    }
                    if response.statusCode != 200 {
                        throw BaseError.generic("OOPS")
                    }
                    let symlinkURL = localURL.appendingPathExtension("splat")
                    try FileManager().createSymbolicLink(at: symlinkURL, withDestinationURL: localURL)
                    subtitle = "Processing"
                    splatCloud = try SplatCloud<SplatC>(device: device, url: symlinkURL, splatLimit: splatLimit)
                default:
                    splatCloud = try SplatCloud<SplatC>(device: device, url: url, splatLimit: splatLimit)
                }
            }
            catch {
                fatalError(error)
            }
        }
    }
}

public struct GaussianSplatNewMinimalView: View {
    let initialSplatCloud: SplatCloud<SplatC>
    let initialConfiguration: GaussianSplatRenderingConfiguration

    @Environment(\.metalDevice)
    private var device

    @Environment(\.logger)
    private var logger

    @State
    private var viewModel: GaussianSplatViewModel<SplatC>?

    public init(splatCloud: SplatCloud<SplatC>, configuration: GaussianSplatRenderingConfiguration = .init()) {
        self.initialSplatCloud = splatCloud
        self.initialConfiguration = configuration
    }

    public var body: some View {
        ZStack {
            if let viewModel {
                GaussianSplatNewMinimalView_()
                    .environment(viewModel)
            }
        }
        .task {
            do {
                let panoramaMesh = try Sphere3D(radius: 400).toMTKMesh(device: device, inwardNormals: true)
                let loader = MTKTextureLoader(device: device)
                let panoramaTexture = try loader.newTexture(name: "SplitSkybox", scaleFactor: 2, bundle: Bundle.module)
                let root = Node(label: "root") {
                    Node(label: "camera", content: Camera())
                    Node(label: "pano", content: Geometry(mesh: panoramaMesh, materials: [UnlitMaterialX(baseColorTexture: panoramaTexture)]))
                    Node(label: "splats", content: initialSplatCloud).transformed(roll: .zero, pitch: .degrees(270), yaw: .zero).transformed(roll: .zero, pitch: .zero, yaw: .degrees(90)).transformed(translation: [0, 0.25, 0.5])
                }
                let scene = SceneGraph(root: root)

                viewModel = try GaussianSplatViewModel<SplatC>(device: device, scene: scene, configuration: initialConfiguration, logger: logger)
            }
            catch {
                fatalError(error)
            }
        }
    }
}

struct GaussianSplatNewMinimalView_: View {
    @Environment(\.metalDevice)
    var device

    @Environment(GaussianSplatViewModel<SplatC>.self)
    var viewModel

    @State
    private var cameraCone: CameraCone = .init(apex: [0, 0, 0], axis: [0, 1, 0], h1: 0, r1: 0.5, r2: 0.75, h2: 0.5)

    @State
    private var gpuCounters: GPUCounters?

    internal var body: some View {
        @Bindable
        var viewModel = viewModel

        GaussianSplatRenderView<SplatC>()
            #if os(iOS)
            .ignoresSafeArea()
            #endif
            .modifier(CameraConeController(cameraCone: cameraCone, transform: $viewModel.scene.unsafeCurrentCameraNode.transform))
            .environment(\.gpuCounters, gpuCounters)
            .overlay(alignment: .top) {
                if let gpuCounters {
                    TimelineView(.periodic(from: .now, by: 0.25)) { _ in
                        PerformanceHUD(measurements: gpuCounters.current())
                    }
                }
            }
    }
}
