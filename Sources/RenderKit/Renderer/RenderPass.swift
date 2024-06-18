import Foundation
import Metal
import SwiftGraphicsSupport

public protocol RenderPassState {
}

public protocol RenderPassProtocol: Equatable {
    associatedtype State: RenderPassState
    typealias Context = RenderContext
    var id: AnyHashable { get }
    func setup(context: Context, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State
    func sizeWillChange(context: Context, state: inout State, size: CGSize) throws
    func render(context: Context, state: State, drawableSize: SIMD2<Float>, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) throws
    func encode(context: Context, state: State, drawableSize: SIMD2<Float>, commandEncoder: MTLRenderCommandEncoder) throws
}

// MARK: -

public extension RenderPassProtocol {
    func sizeWillChange(context: Context, state: inout State, size: CGSize) throws {
    }

    func render(context: Context, state: State, drawableSize: SIMD2<Float>, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) throws {
        let commandEncoder = try commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor).safelyUnwrap(RenderKitError.resourceCreationFailure)
        defer {
            commandEncoder.endEncoding()
        }
        try commandEncoder.withDebugGroup("Start encoding for \(type(of: self))") {
            commandEncoder.label = "\(type(of: self))"
            try encode(context: context, state: state, drawableSize: drawableSize, commandEncoder: commandEncoder)
        }
    }
}

// MARK: -

public extension RenderPassProtocol {
    func sizeWillChange(context: Context, untypedState: inout any RenderPassState, size: CGSize) throws {
        guard var state = untypedState as? State else {
            fatalError()
        }
        try sizeWillChange(context: context, state: &state, size: size)
        untypedState = state
    }

    func render(context: Context, untypedState: any RenderPassState, drawableSize: SIMD2<Float>, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) throws {
        guard let state = untypedState as? State else {
            fatalError()
        }
        try render(context: context, state: state, drawableSize: drawableSize, renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
}
