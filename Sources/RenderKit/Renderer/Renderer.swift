import BaseSupport
import Combine
import MetalKit
import MetalSupport
import MetalUISupport
import ModelIO
import os.log
import RenderKitShadersLegacy
import simd
import SIMDSupport
import SwiftUI

public protocol MetalConfigurationProtocol {
    var colorPixelFormat: MTLPixelFormat { get set }
    var clearColor: MTLClearColor { get set }
    var depthStencilPixelFormat: MTLPixelFormat { get set }
    var depthStencilStorageMode: MTLStorageMode { get set }
    var clearDepth: Double { get set }
}

extension MetalViewConfiguration: MetalConfigurationProtocol {
}

struct Renderer <MetalConfiguration> where MetalConfiguration: MetalConfigurationProtocol {
    private var device: MTLDevice
    private var passes: PassCollection
    private var statesByPasses: [AnyHashable: any PassState] = [:]
    private var configuration: MetalConfiguration?
    private var drawableSize: CGSize = .zero
    private var logger: Logger? = Logger(subsystem: "com.swiftui.metal", category: "Renderer")

    enum State: Equatable {
        case initialized
        case configured(sizeKnown: Bool)
        case rendering
    }
    var state: State

    init(device: MTLDevice, passes: PassCollection) {
        print("INIT: \(type(of: self))")
        self.device = device
        self.passes = passes
        self.state = .initialized
    }

    mutating func configure(_ configuration: inout MetalConfiguration) throws {
        assert(state == .initialized)
        self.state = .configured(sizeKnown: false)
        configuration.colorPixelFormat = .bgra8Unorm_srgb
        configuration.depthStencilPixelFormat = .depth32Float
        self.configuration = configuration
        try setupPasses(passes: passes.elements)
    }

    mutating func sizeWillChange(_ size: CGSize) throws {
        assert(state != .initialized)
        state = .configured(sizeKnown: true)
        drawableSize = size
        for renderPass in passes.renderPasses {
            guard var state = statesByPasses[renderPass.id] else {
                fatalError()
            }
            try renderPass.sizeWillChange(device: device, untypedState: &state, size: size)
            statesByPasses[renderPass.id] = state
        }
    }

    mutating func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, drawableSize: CGSize) throws {
        assert(state == .configured(sizeKnown: true) || state == .rendering)
        if state != .rendering {
            state = .rendering
        }

        let passes = try expand(passes: passes.elements)

        let renderPasses = passes.compactMap { $0 as? any RenderPassProtocol }

        for pass in passes {
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
                guard var state = statesByPasses[pass.id] else {
                    fatalError()
                }
                try pass.render(device: device, untypedState: &state, drawableSize: SIMD2<Float>(drawableSize), renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
                statesByPasses[pass.id] = state
            case let pass as any ComputePassProtocol:
                guard var state = statesByPasses[pass.id] else {
                    fatalError()
                }
                try pass.compute(device: device, untypedState: &state, commandBuffer: commandBuffer)
                statesByPasses[pass.id] = state
            case let pass as any GeneralPassProtocol:
                guard var state = statesByPasses[pass.id] else {
                    fatalError()
                }
                try pass.encode(device: device, untypedState: &state, commandBuffer: commandBuffer)
                statesByPasses[pass.id] = state
            default:
                fatalError()
            }
        }
    }

    mutating func draw(commandQueue: MTLCommandQueue, renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable, drawableSize: CGSize) throws {
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

    mutating func setupPasses(passes: [any PassProtocol]) throws {
        guard let configuration else {
            fatalError()
        }
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
            logger?.info("Pass removed: \(pass.id)")
            statesByPasses[pass.id] = nil
        }
        let insertions = difference.insertions.map(\.element)
        try setupPasses(passes: insertions)
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
