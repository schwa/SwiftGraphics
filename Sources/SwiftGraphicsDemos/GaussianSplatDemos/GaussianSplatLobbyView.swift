import GaussianSplatSupport
import RenderKit
import SwiftUI
import Constraints3D

public struct GaussianSplatLobbyView: View {
    @Environment(\.metalDevice)
    var device

    @State
    private var configuration: GaussianSplatRenderingConfiguration = .init(bounds: ConeBounds(bottomHeight: 0.05, bottomInnerRadius: 0.4, topHeight: 0.8, topInnerRadius: 0.8)) // Random!

    @State
    private var splatLimit: Int = 2_000_000

    @State
    private var useGPUCounters = false

    @State
    private var progressiveLoad = false

    @State
    private var backgroundColor = Color.black

    @State
    private var source: SplatResource

    let sources: [SplatResource]

    enum Mode {
        case config
        case render
    }

    @State
    private var mode: Mode = .config

    init(sources: [SplatResource]) {
        self.sources = sources
        self.source = sources.first!
    }

    public var body: some View {
        Group {
            switch mode {
            case .config:
                VStack {
                    Form {
                        LabeledContent("Source") {
                            Picker("Source", selection: $source) {
                                ForEach(sources, id: \.self) { source in
                                    Label {
                                        Text(source.name)
                                    } icon: {
                                        switch source.url.scheme {
                                        case "file":
                                            Image(systemName: "doc")
                                        case "http", "https":
                                            Image(systemName: "globe")
                                        default:
                                            EmptyView()
                                        }
                                    }
                                    .tag(source)
                                }
                            }
                            .labelsHidden()
                        }
                        optionsView
                    }
                    Button("Go!") {
                        configuration.bounds = source.bounds
                        mode = .render
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
                .onChange(of: useGPUCounters, initial: true) {
                    if useGPUCounters {
                        let gpuCounters = try! GPUCounters(device: device)
                        configuration.gpuCounters = gpuCounters
                    }
                    else {
                        configuration.gpuCounters = nil
                    }
                }
                .onChange(of: backgroundColor, initial: true) {
                    let color = backgroundColor.resolve(in: .init()).cgColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .perceptual, options: nil)!
                    let components = color.components!
                    configuration.clearColor = MTLClearColor(red: components[0], green: components[1], blue: components[2], alpha: components[3])
                }
                #if os(macOS)
                .frame(width: 320)
                #endif
            case .render:
                GaussianSplatLoadingView(url: source.url, splatResource: source, bounds: source.bounds, initialConfiguration: configuration, splatLimit: splatLimit, progressiveLoad: progressiveLoad)
                    .overlay(alignment: .topLeading) {
                        Button("Back") {
                            mode = .config
                        }
                        #if os(macOS)
                        .buttonStyle(.link)
                        #endif
                        .padding()
                    }
                    .environment(\.gpuCounters, configuration.gpuCounters)
            }
        }
    }

    @ViewBuilder
    var optionsView: some View {
        Section("Options") {
            LabeledContent("MetalFX Rate") {
                VStack(alignment: .leading) {
                    TextField("MetalFX Rate", value: $configuration.metalFXRate, format: .number)
                        .labelsHidden()
                    Text("This is how much to downscale the splat cloud before rendering, using MetalFX to for AI upscaling.").font(.caption)
                }
            }
            LabeledContent("Discard Rate") {
                VStack(alignment: .leading) {
                    TextField("Discard Rate", value: $configuration.discardRate, format: .number)
                        .labelsHidden()
                    Text("This is the minimum rate for alpha to show a splat. (Should be zero. Higher values mean more splats will be discarded as they are too transparent.)").font(.caption)
                }
            }
            LabeledContent("Vertical Angle of View") {
                VStack(alignment: .leading) {
                    TextField("AoV", value: $configuration.verticalAngleOfView.degrees, format: .number)
                        .labelsHidden()
                    Text("Vertical Angle of View (FOV) in degrees.").font(.caption)
                }
            }

            LabeledContent("Splat Limit") {
                VStack(alignment: .leading) {
                    TextField("Splat Limit", value: $splatLimit, format: .number)
                        .labelsHidden()
                    Text("Limit number of splats to load. This is for testing purposes only (splats are sorted by distance from the center of the splatcloud. This can be expensive).").font(.caption)
                }
            }
            LabeledContent("GPU Counters") {
                VStack(alignment: .leading) {
                    Toggle("GPU Counters", isOn: $useGPUCounters)
                        .labelsHidden()
                    Text("Show info on framerate, GPU usage etc.").font(.caption)
                }
            }
            LabeledContent("Background Color") {
                VStack(alignment: .leading) {
                    ColorPicker("Background Color", selection: $backgroundColor)
                        .labelsHidden()
                    Text("Colour of background (behind the splats)").font(.caption)
                }
            }
            LabeledContent("Progressive Load") {
                VStack(alignment: .leading) {
                    Toggle("Progressive Load", isOn: $progressiveLoad)
                        .labelsHidden()
                    Text("Stream splats in (remote splats only).").font(.caption)
                }
            }
            LabeledContent("GPU Sort") {
                VStack(alignment: .leading) {
                    Toggle("GPU Sort", isOn: $configuration.useGPUSort)
                        .labelsHidden()
                    Text("Use GPU Sorting").font(.caption)
                }
            }
        }
    }
}
