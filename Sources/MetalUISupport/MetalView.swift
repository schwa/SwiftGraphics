import BaseSupport
import Everything
import Metal
import MetalKit
import MetalSupport
import Observation
import os
import SwiftUI

#if !os(visionOS)
public struct MetalViewConfiguration: Sendable {
    // IDEA: Fully expand this as needed.
    public var colorPixelFormat: MTLPixelFormat
    public var clearColor: MTLClearColor
    public var depthStencilPixelFormat: MTLPixelFormat
    public var depthStencilStorageMode: MTLStorageMode
    public var clearDepth: Double
    public var preferredFramesPerSecond: Int
    public var enableSetNeedsDisplay: Bool
    public var framebufferOnly: Bool
}

public struct MetalView: View {
    public typealias Setup = (MTLDevice, inout MetalViewConfiguration) throws -> Void
    public typealias DrawableSizeWillChange = (MTLDevice, inout MetalViewConfiguration, CGSize) throws -> Void
    public typealias Draw = (MTLDevice, MetalViewConfiguration, CGSize, CAMetalDrawable, MTLRenderPassDescriptor) throws -> Void

    @Environment(\.metalDevice)
    var device

    @State
    private var model = MetalViewModel()

    @State
    private var error: Error?

    let setup: Self.Setup
    let drawableSizeWillChange: Self.DrawableSizeWillChange
    let draw: Self.Draw

    @Environment(\.logger)
    private var logger

    public init(setup: @escaping Setup, drawableSizeWillChange: @escaping DrawableSizeWillChange, draw: @escaping Draw) {
        self.setup = setup
        self.drawableSizeWillChange = drawableSizeWillChange
        self.draw = draw
    }

    public var body: some View {
        Group {
            if let error {
                ContentUnavailableView(String(describing: error), systemImage: "exclamationmark.triangle")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ViewAdaptor<MTKView> {
                    logger?.debug("ViewAdaptor.Make")
                    let view = MTKView()
                    view.device = device
                    view.delegate = model
                    #if os(macOS)
                    view.layer?.isOpaque = false
                    #endif
                    model.view = view
                    return view
                } update: { _ in
                    //                    logger?.debug("ViewAdaptor.Update")
                }
            }
        }
        .onChange(of: model, initial: true) {
            logger?.debug("ViewAdaptor.onChange(of: model)")
            model.logger = logger
            model.setupCallback = setup
            model.drawableSizeWillChangeCallback = drawableSizeWillChange
            model.drawCallback = draw
            model.doSetup()
        }

        .onChange(of: model.error.0) {
            error = model.error.1
        }
    }
}

@Observable
@MainActor
internal class MetalViewModel: NSObject, MTKViewDelegate {
    var view: MTKView?
    var error: (Int, Error?) = (0, nil)
    var logger: Logger?
    var setupCallback: MetalView.Setup?
    var drawableSizeWillChangeCallback: MetalView.DrawableSizeWillChange?
    var drawCallback: MetalView.Draw?

    // MARK: MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        logger?.debug("MetalViewModel.\(#function)")
        guard let device = view.device else {
            fatalError("No device in `\(#function)`.")
        }
        guard let drawableSizeWillChangeCallback else {
            return
        }
        do {
            var configuration = view.configuration
            guard size != .zero else {
                fatalError("Zero size metal view.")
            }
            try drawableSizeWillChangeCallback(device, &configuration, size)
            view.configuration = configuration
            if view.enableSetNeedsDisplay {
                #if os(macOS)
                view.needsDisplay = true
                #endif
            }
        } catch {
            set(error: error)
        }
    }

    func draw(in view: MTKView) {
        // logger?.debug("MetalViewModel.\(#function)")
        guard let device = view.device, let currentDrawable = view.currentDrawable, let currentRenderPassDescriptor = view.currentRenderPassDescriptor, let drawCallback else {
            fatalError("No device, drawable, or draw in `\(#function)`.")
        }
        do {
            try drawCallback(device, view.configuration, view.drawableSize, currentDrawable, currentRenderPassDescriptor)
        } catch {
            set(error: error)
        }
    }

    // MARK: -

    func doSetup() {
        logger?.debug("MetalViewModel.\(#function)")
        guard let view, let device = view.device, let setupCallback else {
            fatalError("No device or setup in `\(#function)`.")
        }
        do {
            var configuration = view.configuration
            try setupCallback(device, &configuration)
            if view.drawableSize != .zero {
                try drawableSizeWillChangeCallback?(device, &configuration, view.drawableSize)
            }
            view.configuration = configuration
        } catch {
            set(error: error)
        }
    }

    func set(error: Error) {
        logger?.debug("MetalViewModel.\(#function)")
        self.error = (self.error.0 + 1, error)
    }
}

extension MTKView {
    var configuration: MetalViewConfiguration {
        get {
            .init(
                colorPixelFormat: colorPixelFormat,
                clearColor: clearColor,
                depthStencilPixelFormat: depthStencilPixelFormat,
                depthStencilStorageMode: depthStencilStorageMode,
                clearDepth: clearDepth,
                preferredFramesPerSecond: preferredFramesPerSecond,
                enableSetNeedsDisplay: enableSetNeedsDisplay,
                framebufferOnly: framebufferOnly
            )
        }
        set {
            if newValue.colorPixelFormat != colorPixelFormat {
                colorPixelFormat = newValue.colorPixelFormat
            }
            if SIMD4(newValue.clearColor) != SIMD4(clearColor) {
                clearColor = newValue.clearColor
            }
            if newValue.depthStencilPixelFormat != depthStencilPixelFormat {
                depthStencilPixelFormat = newValue.depthStencilPixelFormat
            }
            if newValue.depthStencilStorageMode != depthStencilStorageMode {
                depthStencilStorageMode = newValue.depthStencilStorageMode
            }
            if newValue.clearDepth != clearDepth {
                clearDepth = newValue.clearDepth
            }
            if newValue.preferredFramesPerSecond != preferredFramesPerSecond {
                preferredFramesPerSecond = newValue.preferredFramesPerSecond
            }
            if newValue.enableSetNeedsDisplay != enableSetNeedsDisplay {
                enableSetNeedsDisplay = newValue.enableSetNeedsDisplay
            }
            if newValue.framebufferOnly != framebufferOnly {
                framebufferOnly = newValue.framebufferOnly
            }
        }
    }
}
#endif
