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

public protocol PassState /*: Sendable*/ {
}

public protocol PassProtocol: Equatable/*, Sendable*/ {
    associatedtype State: PassState
    var id: AnyHashable { get }
}

struct Renderer {
    private var device: MTLDevice
    private var passes: PassCollection
    private var statesByPasses: [AnyHashable: any PassState] = [:]
    private var configuration: MetalViewConfiguration?
    private var drawableSize: CGSize = .zero
    private var logger: Logger? = Logger(subsystem: "com.swiftui.metal", category: "Renderer")

    enum State: Equatable {
        case initialized
        case configured(sizeKnown: Bool)
        case rendering
    }
    var state: State {
        didSet {
            //            let state = state
            //            logger?.info("State change: \(String(describing: oldValue)) -> \(String(describing: state))")
        }
    }

    init(device: MTLDevice, passes: PassCollection) {
        self.device = device
        self.passes = passes
        self.state = .initialized
    }

    mutating func configure(_ configuration: inout MetalViewConfiguration) throws {
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

    mutating func draw(commandQueue: MTLCommandQueue, renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable, drawableSize: CGSize) throws {
        assert(state == .configured(sizeKnown: true) || state == .rendering)
        if state != .rendering {
            state = .rendering
        }
        let commandBuffer = try commandQueue.makeCommandBuffer().safelyUnwrap(RenderKitError.resourceCreationFailure)

        for pass in passes.elements {
            //print("TODO: Fix load/store")
            switch pass {
            case let renderPass as any RenderPassProtocol:
                // TODO: FIXME
                //                let isFirst = index == passes.renderPasses.startIndex
                //                let isLast = index == passes.renderPasses.endIndex - 1
                //                if isFirst {
                //                    renderPassDescriptor.colorAttachments[0].loadAction = .clear
                //                    renderPassDescriptor.depthAttachment.loadAction = .clear
                //                }
                //                else {
                //                    renderPassDescriptor.colorAttachments[0].loadAction = .load
                //                    renderPassDescriptor.depthAttachment.loadAction = .load
                //                }
                //                if isLast {
                //                    renderPassDescriptor.colorAttachments[0].storeAction = .store
                //                    renderPassDescriptor.depthAttachment.storeAction = .dontCare
                //                }
                //                else {
                //                    renderPassDescriptor.colorAttachments[0].storeAction = .store
                //                    renderPassDescriptor.depthAttachment.storeAction = .store
                //                }
                guard var state = statesByPasses[renderPass.id] else {
                    fatalError()
                }
                try renderPass.render(device: device, untypedState: &state, drawableSize: SIMD2<Float>(drawableSize), renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
                statesByPasses[renderPass.id] = state
            case let computePass as any ComputePassProtocol:
                guard var state = statesByPasses[computePass.id] else {
                    fatalError()
                }
                try computePass.compute(device: device, untypedState: &state, commandBuffer: commandBuffer)
                statesByPasses[computePass.id] = state
            default:
                fatalError()
            }
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    mutating func setupPasses(passes: [any PassProtocol]) throws {
        guard let configuration else {
            fatalError()
        }
        for pass in passes {
            switch pass {
            case let renderPass as any RenderPassProtocol:
                let renderPipelineDescriptor = {
                    let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
                    renderPipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat
                    renderPipelineDescriptor.depthAttachmentPixelFormat = configuration.depthStencilPixelFormat
                    return renderPipelineDescriptor
                }
                let state = try renderPass.setup(device: device, renderPipelineDescriptor: renderPipelineDescriptor)
                statesByPasses[renderPass.id] = state
            case let computePass as any ComputePassProtocol:
                let state = try computePass.setup(device: device)
                statesByPasses[computePass.id] = state
            default:
                fatalError("Unsupported pass type: \(pass).")
            }
        }
    }

    mutating func updateRenderPasses(_ passes: PassCollection) throws {
        let difference = passes.elements.difference(from: self.passes.elements) { lhs, rhs in
            lhs.id == rhs.id
        }
        if !difference.isEmpty {
            logger?.info("Passes content changed.")
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
