import MetalSupport
import MetalUISupport
import ModelIO
import Observation
import os.log
import RenderKitShadersLegacy
import simd
import SIMDSupport
import SwiftUI

/// A View that can render Metal graphics with an array of `RenderPass` types. This is a relatively low level view and should generally not be used by consumers.
public struct RenderView: View {
    public typealias Configure = (inout MetalViewConfiguration) -> Void
    public typealias SizeWillChange = (MTLDevice, inout MetalViewConfiguration, CGSize) -> Void

    var passes: PassCollection
    var configure: Configure
    var sizeWillChange: SizeWillChange

    @Environment(\.metalDevice)
    var device

    @State
    private var renderer: Renderer<MetalViewConfiguration>?

    @State
    private var commandQueue: MTLCommandQueue?

    @Environment(\.logger)
    private var logger

    @Environment(\.renderErrorHandler)
    var renderErrorHandler

    @Environment(\.rendererCallbacks)
    var rendererCallbacks

    @Environment(\.gpuCounters)
    var gpuCounters

    public init(passes: [any PassProtocol], configure: @escaping Configure = { _ in }, sizeWillChange: @escaping SizeWillChange = { _, _, _ in }) {
        self.configure = configure
        self.sizeWillChange = sizeWillChange
        let passes = PassCollection(passes)
        self.passes = passes
    }

    public var body: some View {
        MetalView { _, configuration in
            do {
                configure(&configuration)
                commandQueue = device.makeCommandQueue().forceUnwrap("Could not create command queue.")

                var callbacks = rendererCallbacks ?? RendererCallbacks()
                if let gpuCounters {
                    // TODO: FIXME these over-write any callbacks passed in
                    callbacks.renderCompleted = { _ in
                        try! gpuCounters.gatherData()
                    }
                    callbacks.prePass = { _, _, passInfo in
                        guard let renderPassDescriptor = passInfo.currentRenderPassDescriptor else {
                            fatalError("Could not get current render pass descriptor.")
                        }
                        gpuCounters.updateBuffer(renderPassDescriptor: renderPassDescriptor)
                    }
                }

                renderer = Renderer<MetalViewConfiguration>(device: device, passes: passes, logger: logger, callbacks: callbacks)
                try renderer?.configure(&configuration)
            } catch {
                renderErrorHandler.send(error, logger: logger)
            }
        } drawableSizeWillChange: { device, configuration, size in
            do {
                try renderer?.drawableSizeWillChange(SIMD2<Float>(size))
                sizeWillChange(device, &configuration, size)
            } catch {
                renderErrorHandler.send(error, logger: logger)
            }
        } draw: { _, _, size, currentDrawable, currentRenderPassDescriptor in
            do {
                guard let commandQueue else {
                    fatalError("No command queue")
                }
                try renderer?.draw(commandQueue: commandQueue, currentRenderPassDescriptor: currentRenderPassDescriptor, currentDrawable: currentDrawable, drawableSize: SIMD2<Float>(size))
            } catch {
                renderErrorHandler.send(error, logger: logger)
            }
        }
        .onChange(of: passes) {
            do {
                try renderer?.updateRenderPasses(passes)
            } catch {
                renderErrorHandler.send(error, logger: logger)
            }
        }
    }
}

// TODO: Idea for later. Might make it easier to dynamically create render pass collections? (when fully fleshed out with conditional support etc).
// @resultBuilder public struct RenderPassBuilder {
//    public static func buildBlock(_ components: any RenderPassProtocol...) -> RenderPassCollection {
//        components
//    }
// }
//

public extension RenderView {
    init(pass: (any PassProtocol)?, configure: @escaping Configure = { _ in }, sizeWillChange: @escaping SizeWillChange = { _, _, _ in }) {
        self.init(passes: pass.map { [$0] } ?? [], configure: configure, sizeWillChange: sizeWillChange)
    }
}

// TODO: Replace with RendererCallbacks \.callbacks
public extension EnvironmentValues {
    @Entry
    var rendererCallbacks: RendererCallbacks?
}
