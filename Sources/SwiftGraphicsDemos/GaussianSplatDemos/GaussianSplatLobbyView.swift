import Constraints3D
import GaussianSplatSupport
import MetalKit
import RenderKit
import SwiftUI

public struct GaussianSplatLobbyView: View {
    @Environment(\.metalDevice)
    var device

    @State
    private var configuration: GaussianSplatConfiguration = .init()

    @State
    private var useGPUCounters = false

    @State
    private var progressiveLoad = true

    @State
    private var backgroundColor = Color.white

    @State
    private var useSkyboxGradient = true

    @State
    private var skyboxGradient: LinearGradient = .init(
        stops: [
            .init(color: .white, location: 0),
            .init(color: .white, location: 0.4),
            .init(color: Color(red: 0.5294117647058824, green: 0.807843137254902, blue: 0.9215686274509803), location: 0.5),
            .init(color: Color(red: 0.5294117647058824, green: 0.807843137254902, blue: 0.9215686274509803), location: 1)
        ],
        startPoint: .init(x: 0, y: 0),
        endPoint: .init(x: 0, y: 1)
    )

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
                    Button("Use Debug Colors") {
                        backgroundColor = .init(red: 1, green: 1, blue: 1)
                        skyboxGradient = .init(stops: [
                            .init(color: .init(red: 1, green: 0, blue: 0).opacity(0), location: 1),
                            .init(color: .init(red: 1, green: 0, blue: 0).opacity(1), location: 0)
                        ],
                        startPoint: .init(x: 0, y: 0),
                        endPoint: .init(x: 0, y: 1)
                        )
                    }
                    Button("Go!") {
//                        configuration.bounds = source.bounds
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
                .onChange(of: skyboxGradient, initial: true) {
                    updateSkyboxTexture()
                }
                #if os(macOS)
                .frame(width: 320)
                #endif
            case .render:
                GaussianSplatLoadingView(url: source.url, splatResource: source, bounds: source.bounds, initialConfiguration: configuration, progressiveLoad: progressiveLoad)
                    .toolbar {
                        ToolbarItem(placement: .navigation) {
                            Button("Back") {
                                mode = .config
                            }
                            #if os(macOS)
                            .buttonStyle(.link)
                            #endif
                        }
                    }
                    .environment(\.gpuCounters, configuration.gpuCounters)
            }
        }
    }

    func updateSkyboxTexture() {
        if useSkyboxGradient {
            let image = skyboxGradient.image(size: .init(width: 1024, height: 1024))

            guard var cgImage = ImageRenderer(content: image).cgImage else {
                fatalError("Could not render image.")
            }
            let bitmapInfo: CGBitmapInfo
            if cgImage.byteOrderInfo == .order32Little {
                bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            } else {
                bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
            }
            cgImage = cgImage.convert(bitmapInfo: bitmapInfo)!
            let textureLoader = MTKTextureLoader(device: device)
            let texture = try! textureLoader.newTexture(cgImage: cgImage, options: nil)
            texture.label = "Skybox Gradient"
            configuration.skyboxTexture = texture
        }
        else {
            configuration.skyboxTexture = nil
        }
    }

    @ViewBuilder
    var optionsView: some View {
        Section("Options") {
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
            LabeledContent("Skybox Gradient") {
                VStack(alignment: .leading) {
                    Toggle("Skybox Gradient", isOn: $useSkyboxGradient)
                    if useSkyboxGradient {
                        LinearGradientEditor(value: $skyboxGradient)
                    }
                    Text("Use a gradient skybox (above the background color, behind the splats)").font(.caption)
                }
            }
            LabeledContent("Progressive Load") {
                VStack(alignment: .leading) {
                    Toggle("Progressive Load", isOn: $progressiveLoad)
                        .labelsHidden()
                    Text("Stream splats in (remote splats only).").font(.caption)
                }
            }
            GaussianSplatConfigurationView(configuration: $configuration)
        }
    }
}
