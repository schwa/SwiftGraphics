import Constraints3D
import GaussianSplatSupport
import MetalKit
import RenderKit
import SwiftUI

public struct GaussianSplatLobbyView: View {
    @Environment(\.metalDevice)
    var device

    @State
    private var configuration: GaussianSplatConfiguration = .init(bounds: ConeBounds(bottomHeight: 0.05, bottomInnerRadius: 0.4, topHeight: 0.8, topInnerRadius: 0.8)) // Random!

    @State
    private var splatLimit: Int = 2_000_000

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
                .onChange(of: skyboxGradient, initial: true) {
                    updateSkyboxTexture()
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

    func updateSkyboxTexture() {
        if useSkyboxGradient {
            let image = skyboxGradient.image(size: .init(width: 1024, height: 1024))

            guard var cgImage = ImageRenderer(content: image).cgImage else {
                fatalError()
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
            print("Set skyboxTexture to \(texture)")
        }
        else {
            configuration.skyboxTexture = nil
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

extension CGImage {
    func convert(bitmapInfo: CGBitmapInfo) -> CGImage? {
        let width = width
        let height = height
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}

func convertCGImageEndianness2(_ inputImage: CGImage) -> CGImage? {
    let width = inputImage.width
    let height = inputImage.height
    let bitsPerComponent = 8
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    // Choose the appropriate bitmap info for the target endianness
    let bitmapInfo: CGBitmapInfo
    if inputImage.byteOrderInfo == .order32Little {
        bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
    } else {
        bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
    }

    guard let context = CGContext(data: nil,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: bitsPerComponent,
                                  bytesPerRow: bytesPerRow,
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo.rawValue) else {
        return nil
    }

    // Draw the original image into the new context
    context.draw(inputImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    // Create a new CGImage from the context
    return context.makeImage()
}
