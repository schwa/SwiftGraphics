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

public struct GaussianSplatRenderView <Splat>: View where Splat: SplatProtocol {


    @State
    private var drawableSize: SIMD2<Float> = .zero

    @Environment(GaussianSplatViewModel<Splat>.self)
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
                let size = SIMD2<Float>(size)
                guard drawableSize != size else {
                    return
                }
                drawableSize = SIMD2<Float>(size)
                try viewModel.drawableChanged(pixelFormat: configuration.colorPixelFormat, size: drawableSize)
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

// MARK: -
