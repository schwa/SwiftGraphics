import GaussianSplatSupport
import RenderKit
import SwiftUI

public struct GaussianSplatLobbyView: View {
    @Environment(\.metalDevice)
    var device

    @State
    private var configuration: GaussianSplatRenderingConfiguration = .init()

    @State
    private var splatLimit: Int = 1_500_000

    @State
    private var useGPUCounters = false

    @State
    private var backgroundColor = Color.blue

    @State
    private var source: URL

    let sources: [URL]

    enum Mode {
        case config
        case render
    }

    @State
    private var mode: Mode = .config

    init(sources: [URL]) {
        self.sources = sources
        self.source = sources.first!
    }

    public var body: some View {
        Group {
            switch mode {
            case .config:
                VStack {
                    LabeledContent("Source") {
                        Picker("Source", selection: $source) {
                            ForEach(sources, id: \.self) { source in
                                Label {
                                    Text(source.deletingPathExtension().lastPathComponent)
                                } icon: {
                                    Image(systemName: "doc")
                                }
                                .tag(source)
                            }
                        }
                        .labelsHidden()
                    }
                    Form {
                        optionsView
                    }
                    Button("Go!") {
                        mode = .render
                    }
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
                GaussianSplatLoadingView(url: source, initialConfiguration: configuration, splatLimit: splatLimit)
                    .overlay(alignment: .topLeading) {
                        Button("Back") {
                            mode = .config
                        }
                        .buttonStyle(.link)
                        .padding()
                    }
            }
        }
    }

    @ViewBuilder
    var optionsView: some View {
        Section("Options") {
            LabeledContent("Sort Rate") {
                VStack(alignment: .leading) {
                    TextField("Sort Rate", value: $configuration.sortRate, format: .number)
                        .labelsHidden()
                    Text("This is the # of samples to sort before re-sorting the splat cloud.").font(.caption)
                }
            }
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
                    Text("TODO").font(.caption)
                }
            }
        }
    }
}

extension GaussianSplatLobbyView: DemoView {
    init() {
        self.init(sources: [Bundle.main.url(forResource: "vision_dr", withExtension: "splat", recursive: true)!])
    }
}
