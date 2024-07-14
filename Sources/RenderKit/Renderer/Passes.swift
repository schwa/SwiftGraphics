import Metal

public protocol PassProtocol: Equatable/*, Sendable*/ {
    var id: AnyHashable { get }
}

// TODO: Make sendable.
// TODO: Allow for empty state - make Never or () conform to PassState???
public protocol PassState /*: Sendable*/ {
}

// MARK: -

public protocol ShaderPassProtocol: PassProtocol {
    associatedtype State: PassState
}

// MARK: -

public protocol ComputePassProtocol: ShaderPassProtocol {
    func setup(device: MTLDevice) throws -> State
    func compute(state: inout State, commandBuffer: MTLCommandBuffer) throws
}

// MARK: -

public protocol RenderPassProtocol: ShaderPassProtocol {
    func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State
    func sizeWillChange(device: MTLDevice, state: inout State, size: CGSize) throws
    func render(commandBuffer: MTLCommandBuffer, state: inout State, drawableSize: SIMD2<Float>, renderPassDescriptor: MTLRenderPassDescriptor) throws
    func encode(commandEncoder: MTLRenderCommandEncoder, state: inout State, drawableSize: SIMD2<Float>) throws
}

// MARK: -

public protocol GeneralPassProtocol: PassProtocol {
    associatedtype State: PassState
    func setup(device: MTLDevice) throws -> State
    func encode(state: inout State, commandBuffer: MTLCommandBuffer) throws // TODO: Rename
}

// MARK: -

public protocol GroupPassProtocol: PassProtocol {
    func children() throws -> [any PassProtocol]
}
