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
}

extension MetalViewConfiguration: MetalConfigurationProtocol {
}

struct Renderer <MetalConfiguration>: Sendable where MetalConfiguration: MetalConfigurationProtocol {
    private var device: MTLDevice
    private var passes: PassCollection
    private var statesByPasses: [PassID: any PassState] = [:]
    private var configuration: MetalConfiguration?
    private var drawableSize: SIMD2<Float> = .zero
    private var logger: Logger? = Logger(subsystem: "com.swiftui.metal", category: "Renderer")

    private var info: PassInfo?

    enum Phase: Equatable {
        case initialized
        case configured(sizeKnown: Bool)
        case rendering
    }
    var phase: Phase

    init(device: MTLDevice, passes: PassCollection) {
        self.device = device
        self.passes = passes
        self.phase = .initialized
    }

    mutating func configure(_ configuration: inout MetalConfiguration) throws {
        assert(phase == .initialized)
        self.phase = .configured(sizeKnown: false)
        configuration.colorPixelFormat = .bgra8Unorm_srgb
        //configuration.depthStencilPixelFormat = .depth32Float
        try setupPasses(passes: passes.elements, configuration: &configuration)
        self.configuration = configuration
    }

    mutating func sizeWillChange(_ size: SIMD2<Float>) throws {
        assert(phase != .initialized)
        phase = .configured(sizeKnown: true)
        drawableSize = size
        for renderPass in passes.renderPasses {
            guard var state = statesByPasses[renderPass.id] else {
                fatalError("Could not get state for render pass.")
            }
            try renderPass.sizeWillChange(device: device, size: size, untypedState: &state)
            statesByPasses[renderPass.id] = state
        }
    }

    mutating func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, drawableSize: SIMD2<Float>) throws {
        assert(phase == .configured(sizeKnown: true) || phase == .rendering)
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
            guard let configuration = configuration else {
                fatalError("Could not unwrap configuration.")
            }
            info = PassInfo(drawableSize: drawableSize, frame: 0, start: now, time: now, deltaTime: 0, configuration: configuration)
        }
        guard let info else {
            fatalError("Could not unwrap info.")
        }
        try _render(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor, passes: passes, info: info)
    }

    private func _render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, passes: PassCollection, info: PassInfo) throws {
        assert(phase == .configured(sizeKnown: true) || phase == .rendering)

        let passes = try expand(passes: passes.elements)

        let renderPasses = passes.compactMap { $0 as? any RenderPassProtocol }

        for pass in passes {
            guard let state = statesByPasses[pass.id] else {
                fatalError("Could not get state for pass")
            }
            switch pass {
            case let pass as any RenderPassProtocol:
                let isFirst = pass.id == renderPasses.first?.id
                let isLast = pass.id == renderPasses.last?.id
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
                try pass.render(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor, info: info, untypedState: state)
            case let pass as any ComputePassProtocol:
                try pass.compute(commandBuffer: commandBuffer, info: info, untypedState: state)
            case let pass as any GeneralPassProtocol:
                try pass.encode(commandBuffer: commandBuffer, info: info, untypedState: state)
            default:
                fatalError("Unknown pass type.")
            }
        }
    }

    mutating func draw(commandQueue: MTLCommandQueue, renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable, drawableSize: SIMD2<Float>) throws {
        let commandBuffer = try commandQueue.makeCommandBuffer().safelyUnwrap(BaseError.resourceCreationFailure)
        try render(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor, drawableSize: drawableSize)
        commandBuffer.present(drawable)
        commandBuffer.commit()
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
        guard var configuration = configuration else {
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
