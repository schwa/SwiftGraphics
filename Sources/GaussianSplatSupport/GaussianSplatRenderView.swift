import CoreGraphicsSupport
import MetalKit
import MetalSupport
import RenderKit
import simd
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI

public struct GaussianSplatRenderView: View {
    @State
    private var cameraTransform: Transform = .translation([0, 0, 3])

    @State
    private var cameraProjection: Projection = .perspective(.init())

    @State
    private var modelTransform = Transform.identity.rotated(angle: .degrees(180), axis: [1, 0, 0])

    @State
    private var device: MTLDevice

    @State
    private var debugMode: Bool = false

    @State
    private var sortRate: Int = 10

    @Environment(GaussianSplatViewModel.self)
    var viewModel

    @State
    private var size: CGSize = .zero

    @Environment(\.displayScale)
    var displayScale

    public init(device: MTLDevice) {
        self.device = device
    }

    public var body: some View {
        RenderView(device: device, passes: passes)
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            }
            action: { size in
                self.size = size
            }
            .ballRotation($modelTransform.rotation.rollPitchYaw, pitchLimit: .radians(-.infinity) ... .radians(.infinity))
            .overlay(alignment: .bottom) {
                VStack {
                    Text("Size: [\(size * displayScale, format: .size)]")
                    Text("#splats: \(viewModel.splatCount)")
                    HStack {
                        Slider(value: $cameraTransform.translation.z, in: 0.0 ... 20.0) { Text("Distance") }
                            .frame(maxWidth: 120)
                        TextField("Distance", value: $cameraTransform.translation.z, format: .number)
                            .labelsHidden()
                            .frame(maxWidth: 120)
                    }
                    Toggle("Debug Mode", isOn: $debugMode)
//                    HStack {
//                        Slider(value: $sortRate.toDouble, in: 1 ... 60) { Text("Sort Rate") }
//                            .frame(maxWidth: 120)
//                        Text("\(sortRate)")
//                    }
                }
                .padding()
                .background(.ultraThickMaterial).cornerRadius(8)
                .padding()
            }
    }

    var passes: [any PassProtocol] {
        let preCalcComputePass = GaussianSplatPreCalcComputePass(
            splatCount: viewModel.splatCount,
            splatDistancesBuffer: Box(viewModel.splatDistances),
            splatBuffer: Box(viewModel.splats.splatBuffer),
            modelMatrix: simd_float3x3(truncating: modelTransform.matrix),
            cameraPosition: cameraTransform.translation
        )

        let gaussianSplatSortComputePass = GaussianSplatBitonicSortComputePass(
            splatCount: viewModel.splatCount,
            splatIndicesBuffer: Box(viewModel.splats.indexBuffer),
            splatDistancesBuffer: Box(viewModel.splatDistances),
            sortRate: sortRate
        )

        let gaussianSplatRenderPass = GaussianSplatRenderPass(
            cameraTransform: cameraTransform,
            cameraProjection: cameraProjection,
            modelTransform: modelTransform,
            splatCount: viewModel.splatCount,
            splats: viewModel.splats,
            debugMode: debugMode
        )

        return [
            preCalcComputePass,
            gaussianSplatSortComputePass,
            gaussianSplatRenderPass
        ]
    }
}
