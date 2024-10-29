import BaseSupport
import Metal
#if !targetEnvironment(simulator)
import MetalFX
#endif
import MetalKit
import MetalSupport
import os
import RenderKit
import RenderKitSceneGraph
import Shapes3D
import simd
import SIMDSupport
import SwiftUI
import Traces

@available(iOS 17, macOS 14, visionOS 1, *)
public struct GaussianSplatRenderView: View {

    @Environment(GaussianSplatViewModel.self)
    var viewModel

    public init() {
    }

    public var body: some View {
        // swiftlint:disable:next force_try
        RenderView(pass: viewModel.pass) { configuration in
            configuration.colorPixelFormat = .bgra8Unorm_srgb
            configuration.depthStencilPixelFormat = .depth32Float
            configuration.clearColor = configuration.clearColor
            configuration.framebufferOnly = false
        }
        sizeWillChange: { _, configuration, size in
            do {
                try viewModel.drawableChanged(pixelFormat: configuration.colorPixelFormat, size: SIMD2<Float>(size))
            } catch {
                fatalError("Failed to create texture.")
            }
            Traces.shared.trace(name: "sizeWillChange")
        }
        didDraw: {
            Traces.shared.trace(name: "didDraw")
            viewModel.frame += 1
        }
    }
}
