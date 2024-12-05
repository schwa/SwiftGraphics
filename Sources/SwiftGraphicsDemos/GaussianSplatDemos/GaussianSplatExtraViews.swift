import GaussianSplatSupport
import SwiftUI

struct OptionsView: View {
    struct Options {
        var showInfo: Bool = false
        var showCounters: Bool = false
    }

    @Binding
    var options: Options

    @Binding
    var configuration: GaussianSplatConfiguration

    var body: some View {
        Toggle("Render Splats", isOn: $configuration.renderSplats)
        Toggle("Render Skybox", isOn: $configuration.renderSkybox)
        Toggle("Show Info", isOn: $options.showInfo)
        //        Toggle("Show Counters", isOn: $options.showCounters)

        LabeledContent("MetalFX Rate") {
            TextField("MetalFX Rate", value: $configuration.metalFXRate, format: .number)
                .multilineTextAlignment(.trailing)
        }
        LabeledContent("Discard Rate") {
            TextField("Discard Rate", value: $configuration.discardRate, format: .number)
                .multilineTextAlignment(.trailing)
        }

        LabeledContent("Vertical Angle of View") {
            TextField("Vertical Angle of View", value: $configuration.verticalAngleOfView.degrees, format: .number)
                .multilineTextAlignment(.trailing)
        }
        Picker("Sort Method", selection: $configuration.sortMethod) {
            Text("GPU Bitonic").tag(GaussianSplatConfiguration.SortMethod.gpuBitonic)
            Text("CPU Radix").tag(GaussianSplatConfiguration.SortMethod.cpuRadix)
        }
        #if os(iOS)
        .pickerStyle(.navigationLink)
        #endif

        //        @ViewBuilder
        //        var optionsView: some View {
        //            Section("Options") {
        //                LabeledContent("GPU Counters") {
        //                    VStack(alignment: .leading) {
        //                        Toggle("GPU Counters", isOn: $useGPUCounters)
        //                            .labelsHidden()
        //                        Text("Show info on framerate, GPU usage etc.").font(.caption)
        //                    }
        //                }
        //                LabeledContent("Background Color") {
        //                    VStack(alignment: .leading) {
        //                        ColorPicker("Background Color", selection: $backgroundColor)
        //                            .labelsHidden()
        //                        Text("Colour of background (behind the splats)").font(.caption)
        //                    }
        //                }
        //                LabeledContent("Skybox Gradient") {
        //                    VStack(alignment: .leading) {
        //                        Toggle("Skybox Gradient", isOn: $useSkyboxGradient)
        //                        if useSkyboxGradient {
        //                            LinearGradientEditor(value: $skyboxGradient)
        //                        }
        //                        Text("Use a gradient skybox (above the background color, behind the splats)").font(.caption)
        //                    }
        //                }
        //                LabeledContent("Progressive Load") {
        //                    VStack(alignment: .leading) {
        //                        Toggle("Progressive Load", isOn: $progressiveLoad)
        //                            .labelsHidden()
        //                        Text("Stream splats in (remote splats only).").font(.caption)
        //                    }
        //                }
        //            }

    }
}

struct InfoView: View {
    @Environment(GaussianSplatViewModel.self)
    private var viewModel

    var body: some View {
        VStack {
            Text("# splats: \(viewModel.splatCloud.capacity.formatted())")
            Text("Sort method: \(viewModel.configuration.sortMethod)")
        }
    }
}
