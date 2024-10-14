import GaussianSplatSupport
import SwiftUI

struct GaussianSplatConfigurationView: View {

    @Binding
    var configuration: GaussianSplatConfiguration

    var body: some View {
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
        LabeledContent("GPU Sort") {
            VStack(alignment: .leading) {
                Picker("Sort Method", selection: $configuration.sortMethod) {
                    Text("GPU Bitonic").tag(GaussianSplatConfiguration.SortMethod.gpuBitonic)
                    Text("CPU Radix").tag(GaussianSplatConfiguration.SortMethod.cpuRadix)
                }
                .labelsHidden()
                Text("Use GPU Sorting").font(.caption)
            }
        }
    }
}
