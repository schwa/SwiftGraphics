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

protocol PassState: Equatable, Sendable {
}

protocol PassProtocol: Equatable, Sendable {
    associatedtype State: PassState
    var id: AnyHashable { get }
}

struct Renderer {
    private var renderPasses: RenderPassCollection
    private var renderContext: RenderContext
    private var renderPassState: [AnyHashable: any RenderPassState] = [:]
    private var configuration: MetalViewConfiguration?
    private var drawableSize: CGSize = .zero

    enum State: Equatable {
        case initialized
        case configured(sizeKnown: Bool)
        case rendering
    }
    var state: State {
        didSet {
            let state = state
            renderContext.logger?.info("State change: \(String(describing: oldValue)) -> \(String(describing: state))")
        }
    }

    init(renderPasses: RenderPassCollection, renderContext: RenderContext) {
        self.renderPasses = renderPasses
        self.renderContext = renderContext
        self.state = .initialized
    }

    mutating func configure(_ configuration: inout MetalViewConfiguration) throws {
        assert(state == .initialized)
        self.state = .configured(sizeKnown: false)
        self.configuration = configuration
        configuration.colorPixelFormat = .bgra8Unorm_srgb
        configuration.depthStencilPixelFormat = .depth32Float
        try setupRenderPasses(configuration: configuration)
    }

    mutating func sizeWillChange(_ size: CGSize) throws {
        assert(state != .initialized)
        state = .configured(sizeKnown: true)
        drawableSize = size
        for renderPass in renderPasses.elements {
            guard var state = renderPassState[renderPass.id] else {
                fatalError()
            }
            try renderPass.sizeWillChange(context: renderContext, untypedState: &state, size: size)
            renderPassState[renderPass.id] = state
        }
    }

    mutating func draw(commandQueue: MTLCommandQueue, renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable, drawableSize: CGSize) throws {
        assert(state == .configured(sizeKnown: true) || state == .rendering)
        if state != .rendering {
            state = .rendering
        }
        let commandBuffer = try commandQueue.makeCommandBuffer().safelyUnwrap(RenderKitError.resourceCreationFailure)

        for (index, renderPass) in renderPasses.elements.enumerated() {
            let isFirst = index == renderPasses.elements.startIndex
            let isLast = index == renderPasses.elements.endIndex - 1

            if isFirst {
                renderPassDescriptor.colorAttachments[0].loadAction = .clear
                renderPassDescriptor.depthAttachment.loadAction = .clear
            }
            else {
                renderPassDescriptor.colorAttachments[0].loadAction = .load
                renderPassDescriptor.depthAttachment.loadAction = .load
            }

            if isLast {
                renderPassDescriptor.colorAttachments[0].storeAction = .store
                renderPassDescriptor.depthAttachment.storeAction = .dontCare
            }
            else {
                renderPassDescriptor.colorAttachments[0].storeAction = .store
                renderPassDescriptor.depthAttachment.storeAction = .store
            }

            guard let state = renderPassState[renderPass.id] else {
                fatalError()
            }
            try renderPass.render(context: renderContext, untypedState: state, drawableSize: SIMD2<Float>(drawableSize), renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private mutating func setupRenderPasses(configuration: MetalViewConfiguration) throws {
        for renderPass in renderPasses.elements {
            do {
                let renderPipelineDescriptor = {
                    let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
                    renderPipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat
                    renderPipelineDescriptor.depthAttachmentPixelFormat = configuration.depthStencilPixelFormat
                    return renderPipelineDescriptor
                }

                let state = try renderPass.setup(context: renderContext, renderPipelineDescriptor: renderPipelineDescriptor)
                renderPassState[renderPass.id] = state
            }
            catch {
                print("Error in setup: \(error)")
                throw error
            }
        }
    }

    mutating func updateRenderPasses(_ renderPasses: RenderPassCollection) throws {
        let difference = renderPasses.elements.difference(from: self.renderPasses.elements) { lhs, rhs in
            lhs.id == rhs.id
        }
        if !difference.isEmpty {
            renderContext.logger?.info("renderpasses content changed.")
        }
        for change in difference {
            switch change {
            case .insert(_, element: let renderPass, _):
                let hasState = renderPassState[renderPass.id] != nil
                renderContext.logger?.info("Render pass inserted: \(renderPass.id), has state: \(hasState)")

                let renderPipelineDescriptor = {
                    guard let configuration else {
                        fatalError()
                    }
                    let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
                    renderPipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat
                    renderPipelineDescriptor.depthAttachmentPixelFormat = configuration.depthStencilPixelFormat
                    return renderPipelineDescriptor
                }

                var state = try renderPass.setup(context: renderContext, renderPipelineDescriptor: renderPipelineDescriptor)
                try renderPass.sizeWillChange(context: renderContext, untypedState: &state, size: drawableSize)
                renderPassState[renderPass.id] = state

            case .remove(_, element: let element, _):
                renderContext.logger?.info("Render pass removed: \(element.id)")
                renderPassState[element.id] = nil
            }
        }
        self.renderPasses = renderPasses
    }
}

// No need for this to actually be a colleciton -we just need Equatable
struct RenderPassCollection: Equatable {
    var elements: [any RenderPassProtocol]

    init(_ elements: [any RenderPassProtocol]) {
        self.elements = elements
    }

    static func ==(lhs: Self, rhs: Self) -> Bool {
        let lhs = lhs.elements.map { AnyEquatable($0) }
        let rhs = rhs.elements.map { AnyEquatable($0) }
        return lhs == rhs
    }
}
