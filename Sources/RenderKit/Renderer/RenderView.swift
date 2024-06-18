import Combine
import MetalKit
import MetalSupport
import MetalUISupport
import ModelIO
import os.log
import RenderKitShadersLegacy
import simd
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI

/// A View that can render Metal graphics with an array of `RenderPass` types. This is a relatively low level view and should generally not be used by consumers.
public struct RenderView: View {
    public typealias Configure = (MetalViewConfiguration) -> Void
    public typealias SizeWillChange = (CGSize) -> Void

    var device: MTLDevice
    var renderPasses: PassCollection
    var configure: Configure
    var sizeWillChange: SizeWillChange

    @State
    var commandQueue: MTLCommandQueue?

    @State
    var renderer: Renderer?

    @Environment(\.renderErrorHandler)
    var renderErrorHandler

    @State
    var logger: Logger = Logger(subsystem: "RenderView", category: "RenderView")

    public init(device: MTLDevice, renderPasses: [any RenderPassProtocol], configure: @escaping Configure = { _ in }, sizeWillChange: @escaping SizeWillChange = { _ in }) {
        self.device = device
        self.renderPasses = .init(renderPasses)
        self.configure = configure
        self.sizeWillChange = sizeWillChange
    }

    public var body: some View {
        MetalView { device, configuration in
            do {
                renderer = Renderer(device: device, passes: renderPasses)
                try renderer!.configure(&configuration)
                configure(configuration)
                commandQueue = device.makeCommandQueue()
            } catch {
                renderErrorHandler.send(error, logger: logger)
            }
        } drawableSizeWillChange: { _, _, size in
            do {
                try renderer!.sizeWillChange(size)
                sizeWillChange(size)
            } catch {
                renderErrorHandler.send(error, logger: logger)
            }
        } draw: { _, _, size, drawable, renderPassDescriptor in
            do {
                guard let commandQueue else {
                    fatalError()
                }
                try renderer!.draw(commandQueue: commandQueue, renderPassDescriptor: renderPassDescriptor, drawable: drawable, drawableSize: size)
            } catch {
                renderErrorHandler.send(error, logger: logger)
            }
        }
        .onChange(of: renderPasses) {
            try! renderer?.updateRenderPasses(renderPasses)
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
