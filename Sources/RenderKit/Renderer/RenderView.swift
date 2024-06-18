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

    var renderPasses: PassCollection
    var configure: Configure
    var sizeWillChange: SizeWillChange

    @State
    var commandQueue: MTLCommandQueue?

    @State
    var renderer: Renderer?

    @Environment(\.renderContext)
    var renderContext

    @Environment(\.renderErrorHandler)
    var renderErrorHandler

    public init(renderPasses: [any RenderPassProtocol], configure: @escaping Configure = { _ in }, sizeWillChange: @escaping SizeWillChange = { _ in }) {
        self.renderPasses = .init(renderPasses)
        self.configure = configure
        self.sizeWillChange = sizeWillChange
    }

    public var body: some View {
        let renderContext = renderContext.forceUnwrap("Provide a render context.")

        MetalView { device, configuration in
            do {
                renderer = Renderer(passes: renderPasses, renderContext: renderContext)
                try renderer!.configure(&configuration)
                configure(configuration)
                commandQueue = device.makeCommandQueue()
            } catch {
                renderErrorHandler.send(error, logger: renderContext.logger)
            }
        } drawableSizeWillChange: { _, _, size in
            do {
                try renderer!.sizeWillChange(size)
                sizeWillChange(size)
            } catch {
                renderErrorHandler.send(error, logger: renderContext.logger)
            }
        } draw: { _, _, size, drawable, renderPassDescriptor in
            do {
                guard let commandQueue else {
                    fatalError()
                }
                try renderer!.draw(commandQueue: commandQueue, renderPassDescriptor: renderPassDescriptor, drawable: drawable, drawableSize: size)
            } catch {
                renderErrorHandler.send(error, logger: renderContext.logger)
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
