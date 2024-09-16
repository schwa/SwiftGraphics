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
import SwiftUISupport

public struct GaussianSplatRenderView <Splat>: View where Splat: SplatProtocol {
    @Environment(\.metalDevice)
    var device

    @Environment(\.logger)
    var logger

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
        }
        didDraw: {
            viewModel.frame += 1
        }
    }
}

// MARK: -

public struct GaussianSplatRenderingConfiguration {
    public var debugMode: Bool
    public var metalFXRate: Float
    public var discardRate: Float
    public var gpuCounters: GPUCounters?
    public var clearColor: MTLClearColor
    public var verticalAngleOfView: Angle

    public init(debugMode: Bool = false, metalFXRate: Float = 2, discardRate: Float = 0.0, gpuCounters: GPUCounters? = nil, clearColor: MTLClearColor = .init(red: 0, green: 0, blue: 0, alpha: 1), verticalAngleOfView: Angle = .degrees(90)) {
        self.debugMode = debugMode
        self.metalFXRate = metalFXRate
        self.discardRate = discardRate
        self.gpuCounters = gpuCounters
        self.clearColor = clearColor
        self.verticalAngleOfView = verticalAngleOfView
    }
}
