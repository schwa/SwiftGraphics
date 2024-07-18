import BaseSupport
import Combine
@preconcurrency import Metal
import MetalKit
import MetalSupport
import MetalUISupport
import ModelIO
import os.log
import RenderKitShadersLegacy
import simd
import SIMDSupport
import SwiftUI

public protocol MetalConfigurationProtocol: Sendable {
    var colorPixelFormat: MTLPixelFormat { get set }
    var clearColor: MTLClearColor { get set }
    var depthStencilPixelFormat: MTLPixelFormat { get set }
    var depthStencilStorageMode: MTLStorageMode { get set }
    var clearDepth: Double { get set }
    var framebufferOnly: Bool { get set }
}

extension MetalViewConfiguration: MetalConfigurationProtocol {
}

struct Renderer <MetalConfiguration>: Sendable where MetalConfiguration: MetalConfigurationProtocol {
    enum Phase: Equatable {
        case initialized
        case configured(sizeKnown: Bool)
        case rendering
    }

    private var device: MTLDevice
    private var passes: PassCollection
    private var logger: Logger?

    typealias Callbacks = RendererCallbacks
    private var callbacks: Callbacks

    private var statesByPasses: [PassID: any PassState] = [:]
    private var configuration: MetalConfiguration?
    private var drawableSize: SIMD2<Float> = .zero
    private var info: PassInfo?
    private var phase: Phase {
        didSet {
            let oldValue = oldValue
            let phase = phase
            logger?.debug("Phase change \(oldValue) -> \(phase).")
        }
    }

    init(device: MTLDevice, passes: PassCollection, logger: Logger? = nil, callbacks: Callbacks = .init()) {
        logger?.debug("Renderer.\(#function)")
        self.device = device
        self.passes = passes
        self.phase = .initialized
        self.callbacks = callbacks
    }

    mutating func configure(_ configuration: inout MetalConfiguration) throws {
        logger?.debug("Renderer.\(#function)")
        assert(phase == .initialized)
        self.phase = .configured(sizeKnown: false)
        configuration.colorPixelFormat = .bgra8Unorm_srgb
        // configuration.depthStencilPixelFormat = .depth32Float
        try setupPasses(passes: passes.elements, configuration: &configuration)
        self.configuration = configuration
    }

    mutating func drawableSizeWillChange(_ size: SIMD2<Float>) throws {
        logger?.debug("Renderer.\(#function): \(size)")
        assert(phase != .initialized)
        phase = .configured(sizeKnown: true)
        drawableSize = size
        for renderPass in passes.renderPasses {
            guard var state = statesByPasses[renderPass.id] else {
                fatalError("Could not get state for render pass.")
            }
            try renderPass.drawableSizeWillChange(device: device, size: size, untypedState: &state)
            statesByPasses[renderPass.id] = state
        }
    }

    mutating func render(commandBuffer: MTLCommandBuffer, currentRenderPassDescriptor: MTLRenderPassDescriptor, drawableSize: SIMD2<Float>) throws {
        guard phase == .configured(sizeKnown: true) || phase == .rendering else {
            logger?.debug("Renderer not configured, skipping render.")
            return
        }
        if phase != .rendering {
            phase = .rendering
        }

        let now = Date().timeIntervalSinceReferenceDate
        if var info {
            info.frame += 1
            info.deltaTime = now - info.time
            info.time = now
            info.drawableSize = drawableSize
            self.info = info
        }
        else {
            guard let configuration else {
                fatalError("Could not unwrap configuration.")
            }
            info = PassInfo(drawableSize: drawableSize, frame: 0, start: now, time: now, deltaTime: 0, configuration: configuration)
        }
        guard let info else {
            fatalError("Could not unwrap info.")
        }

        if let preRender = callbacks.preRender {
            preRender(commandBuffer)
        }

        try _render(commandBuffer: commandBuffer, renderPassDescriptor: currentRenderPassDescriptor, passes: passes.elements, info: info)
    }

    private func _render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, passes: [any PassProtocol], info: PassInfo) throws {
        assert(phase == .configured(sizeKnown: true) || phase == .rendering)

        var info = info
        info.currentRenderPassDescriptor = renderPassDescriptor

        for pass in passes {
            if let prePass = callbacks.prePass {
                prePass(pass, commandBuffer, info)
            }

            switch pass {
            case let pass as any RenderPassProtocol:
                // TODO: FIXME. this is still not right.
                //                let isFirst = pass.id == renderPasses.first?.id
                //                let isLast = pass.id == renderPasses.last?.id
                //                if isFirst {
                //                    currentRenderPassDescriptor.colorAttachments[0].loadAction = .clear
                //                    currentRenderPassDescriptor.depthAttachment.loadAction = .clear
                //                }
                //                else {
                //                    currentRenderPassDescriptor.colorAttachments[0].loadAction = .load
                //                    currentRenderPassDescriptor.depthAttachment.loadAction = .load
                //                }
                //                if isLast {
                //                    currentRenderPassDescriptor.colorAttachments[0].storeAction = .store
                //                    currentRenderPassDescriptor.depthAttachment.storeAction = .dontCare
                //                }
                //                else {
                //                    currentRenderPassDescriptor.colorAttachments[0].storeAction = .store
                //                    currentRenderPassDescriptor.depthAttachment.storeAction = .store
                //                }
                guard let state = statesByPasses[pass.id] else {
                    fatalError("Could not get state for pass")
                }
                try pass.render(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor, info: info, untypedState: state)
            case let pass as any ComputePassProtocol:
                guard let state = statesByPasses[pass.id] else {
                    fatalError("Could not get state for pass")
                }
                try pass.compute(commandBuffer: commandBuffer, info: info, untypedState: state)
            case let pass as any GeneralPassProtocol:
                guard let state = statesByPasses[pass.id] else {
                    fatalError("Could not get state for pass")
                }
                try pass.encode(commandBuffer: commandBuffer, info: info, untypedState: state)
            case let pass as any GroupPassProtocol:
                let children = try pass.children()
                try _render(commandBuffer: commandBuffer, renderPassDescriptor: pass.renderPassDescriptor ?? renderPassDescriptor, passes: children, info: info)
            default:
                fatalError("Unknown pass type.")
            }

            if let postPass = callbacks.postPass {
                postPass(pass, commandBuffer, info)
            }
        }
    }

    mutating func draw(commandQueue: MTLCommandQueue, currentRenderPassDescriptor: MTLRenderPassDescriptor, currentDrawable: MTLDrawable, drawableSize: SIMD2<Float>) throws {
        try commandQueue.withCommandBuffer(drawable: currentDrawable) { commandBuffer in
            if let scheduledHandler = callbacks.renderScheduled {
                commandBuffer.addScheduledHandler(scheduledHandler)
            }
            if let completedHandler = callbacks.renderCompleted {
                commandBuffer.addCompletedHandler(completedHandler)
            }
            try render(commandBuffer: commandBuffer, currentRenderPassDescriptor: currentRenderPassDescriptor, drawableSize: drawableSize)
        }
    }

    func expand(passes: [any PassProtocol]) throws -> [any PassProtocol] {
        try passes.flatMap { pass in
            switch pass {
            case let pass as any GroupPassProtocol:
                return try expand(passes: pass.children())
            default:
                return [pass]
            }
        }
    }

    mutating func setupPasses(passes: [any PassProtocol], configuration: inout MetalConfiguration) throws {
        let passes = try expand(passes: passes)
        for pass in passes {
            switch pass {
            case let pass as any RenderPassProtocol:
                let renderPipelineDescriptor = {
                    let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
                    renderPipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat
                    renderPipelineDescriptor.depthAttachmentPixelFormat = configuration.depthStencilPixelFormat
                    return renderPipelineDescriptor
                }
                let state = try pass.setup(device: device, renderPipelineDescriptor: renderPipelineDescriptor)
                statesByPasses[pass.id] = state
            case let pass as any ComputePassProtocol:
                let state = try pass.setup(device: device)
                statesByPasses[pass.id] = state
            case let pass as any GeneralPassProtocol:
                let state = try pass.setup(device: device)
                statesByPasses[pass.id] = state
            default:
                fatalError("Unsupported pass type: \(pass).")
            }
        }
    }

    mutating func updateRenderPasses(_ passes: PassCollection) throws {
        // Expansion makes this overly complex.
        let currentExpandedPasses = try expand(passes: self.passes.elements)
        let newExpandedPasses = try expand(passes: passes.elements)
        let difference = newExpandedPasses.difference(from: currentExpandedPasses) { lhs, rhs in
            lhs.id == rhs.id
        }
        if !difference.isEmpty {
            logger?.info("\(#function): Passes content changed.")
        }
        for pass in difference.removals.map(\.element) {
            logger?.info("Pass removed: \(pass.id.debugDescription)")
            statesByPasses[pass.id] = nil
        }
        let insertions = difference.insertions.map(\.element)
        guard var configuration else {
            fatalError("Configuration must not be nil.")
        }
        try setupPasses(passes: insertions, configuration: &configuration)
        self.configuration = configuration
        self.passes = passes
    }
}

// No need for this to actually be a collection -we just need Equatable
struct PassCollection: Equatable {
    var elements: [any PassProtocol]

    init(_ elements: [any PassProtocol]) {
        self.elements = elements
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        let lhs = lhs.elements.map { AnyEquatable($0) }
        let rhs = rhs.elements.map { AnyEquatable($0) }
        return lhs == rhs
    }

    var renderPasses: [any RenderPassProtocol] {
        elements.compactMap { $0 as? any RenderPassProtocol }
    }

    var computePasses: [any ComputePassProtocol] {
        elements.compactMap { $0 as? any ComputePassProtocol }
    }
}

extension CollectionDifference.Change {
    var element: ChangeElement {
        switch self {
        case .insert(_, let element, _):
            return element
        case .remove(_, let element, _):
            return element
        }
    }
}

extension Renderer.Phase: CustomStringConvertible {
    public var description: String {
        switch self {
        case .initialized:
            return "initialized"
        case .configured(sizeKnown: let sizeKnown):
            return "configured(sizeKnown: \(sizeKnown))"
        case .rendering:
            return "rendering"
        }
    }
}

public struct RendererCallbacks: Sendable {
    public var preRender: (@Sendable (MTLCommandBuffer) -> Void)?
    public var renderScheduled: (@Sendable (MTLCommandBuffer) -> Void)?
    public var renderCompleted: (@Sendable (MTLCommandBuffer) -> Void)?
    public var prePass: (@Sendable (any PassProtocol, MTLCommandBuffer, PassInfo) -> Void)?
    public var postPass: (@Sendable (any PassProtocol, MTLCommandBuffer, PassInfo) -> Void)?

    public
    init(
        preRender: (@Sendable (MTLCommandBuffer) -> Void)? = nil,
        renderScheduled: (@Sendable (MTLCommandBuffer) -> Void)? = nil,
        renderCompleted: (@Sendable (MTLCommandBuffer) -> Void)? = nil,
        prePass: (@Sendable (any PassProtocol, MTLCommandBuffer, PassInfo) -> Void)? = nil,
        postPass: (@Sendable (any PassProtocol, MTLCommandBuffer, PassInfo) -> Void)? = nil
    ) {
        self.preRender = preRender
        self.renderScheduled = renderScheduled
        self.renderCompleted = renderCompleted
    }
}
