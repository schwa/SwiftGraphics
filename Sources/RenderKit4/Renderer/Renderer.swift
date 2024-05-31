import Combine
import MetalKit
import MetalSupport
import MetalUISupport
import ModelIO
import os.log
import RenderKitShaders
import simd
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI

struct Renderer {
    private var renderPasses: RenderPassCollection
    private var renderContext: RenderContext
    private var renderPassContext: RenderPassContext?
    private var renderPassState: [AnyHashable: any RenderPassState] = [:]
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
        configuration.colorPixelFormat = .bgra8Unorm_srgb
        configuration.depthStencilPixelFormat = .depth32Float
        let renderPassContext = RenderPassContext(renderContext: renderContext, colorPixelFormat: configuration.colorPixelFormat, depthAttachmentPixelFormat: configuration.depthStencilPixelFormat)
        self.renderPassContext = renderPassContext
        try setupRenderPasses()
    }

    mutating func sizeWillChange(_ size: CGSize) throws {
        assert(state != .initialized)
        state = .configured(sizeKnown: true)
        drawableSize = size
        guard let renderPassContext else {
            return
        }
        for renderPass in renderPasses.elements {
            guard var state = renderPassState[renderPass.id] else {
                fatalError()
            }
            try renderPass.sizeWillChange(context: renderPassContext, untypedState: &state, size: size)
            renderPassState[renderPass.id] = state
        }
    }

    mutating func draw(commandQueue: MTLCommandQueue, renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable, drawableSize: CGSize) throws {
        assert(state == .configured(sizeKnown: true) || state == .rendering)
        if state != .rendering {
            state = .rendering
        }
        guard let renderPassContext else {
            fatalError("No render pass context found. This should be impossible.")
        }

        let commandBuffer = try commandQueue.makeCommandBuffer().safelyUnwrap(RenderKit4Error.resourceCreationFailure)

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
            try renderPass.render(context: renderPassContext, untypedState: state, renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private mutating func setupRenderPasses() throws {
        guard let renderPassContext else {
            fatalError()
        }
        for renderPass in renderPasses.elements {
            do {
                let state = try renderPass.setup(context: renderPassContext)
                renderPassState[renderPass.id] = state
            }
            catch {
                print("Error in setup: \(error)")
                throw error
            }
        }
    }

    mutating func updateRenderPasses(_ renderPasses: RenderPassCollection) throws {
        guard let renderPassContext else {
            fatalError()
        }
        let difference = renderPasses.elements.difference(from: self.renderPasses.elements) { lhs, rhs in
            lhs.id == rhs.id
        }
        if !difference.isEmpty {
            renderContext.logger?.info("renderpasses content changed.")
        }
        for change in difference {
            switch change {
            case .insert(_, element: let element, _):
                let hasState = renderPassState[element.id] != nil
                renderContext.logger?.info("Render pass inserted: \(element.id), has state: \(hasState)")
                var state = try element.setup(context: renderPassContext)
                try element.sizeWillChange(context: renderPassContext, untypedState: &state, size: drawableSize)
                renderPassState[element.id] = state

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
