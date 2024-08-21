import GaussianSplatSupport
import SwiftUI
import RenderKit

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
    private var source: URL? = Bundle.main.url(forResource: "vision_dr", withExtension: "splat", recursive: true)!

    enum Mode {
        case config
        case render
    }

    @State
    private var mode: Mode = .config

    public var body: some View {
        Group {
            switch mode {
            case .config:
                VStack {
                    Form {
                        optionsView
                    }
                    Button("Go!") {
                        mode = .render
                    }
                }
            case .render:

                let splatCloud = try! SplatCloud<SplatC>(device: device, url: source!)


                try! GaussianSplatNewMinimalView(splatCloud: splatCloud, configuration: configuration)
                    .overlay(alignment: .topLeading) {
                        Button("Back") {
                            mode = .config
                        }
                        .buttonStyle(.link)
                        .padding()
                    }
            }
        }
        .onChange(of: useGPUCounters) {
            if useGPUCounters {
                let gpuCounters = try! GPUCounters(device: device)
                configuration.gpuCounters = gpuCounters
            }
            else {
                configuration.gpuCounters = nil
            }
        }
    }

    @ViewBuilder
    var optionsView: some View {
        Section("Options") {
            LabeledContent("Source") {
                Picker("Source", selection: $source) {
                    Text("vision_dr").tag(Bundle.main.url(forResource: "vision_dr", withExtension: "splat", recursive: true)!)
                }
                .labelsHidden()
            }
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
                    Text("TODO").font(.caption)
                }
            }
            LabeledContent("Splat Limit") {
                VStack(alignment: .leading) {
                    TextField("Splat Limit", value: $splatLimit, format: .number)
                        .labelsHidden()
                    Text("TODO").font(.caption)
                }
            }
            LabeledContent("GPU Counters") {
                VStack(alignment: .leading) {
                    Toggle("GPU Counters", isOn: $useGPUCounters)
                        .labelsHidden()
                    Text("TODO").font(.caption)
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
#if os(macOS)
        .frame(width: 320)
#endif
    }
}

extension GaussianSplatLobbyView: DemoView {
}
