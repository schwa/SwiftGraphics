import Metal

public protocol PassProtocol: Equatable/*, Sendable*/ {
    var id: AnyHashable { get }
}

// TODO: Make sendable.
// TODO: Allow for empty state - make Never or () conform to PassState???
public protocol PassState /*: Sendable*/ {
}

// MARK: -

public protocol ComputePassProtocol: ShaderPassProtocol {
    func setup(device: MTLDevice) throws -> State
    func compute(device: MTLDevice, state: inout State, commandBuffer: MTLCommandBuffer) throws
}

// MARK: -

public protocol RenderPassProtocol: ShaderPassProtocol {
    func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State
    func sizeWillChange(device: MTLDevice, state: inout State, size: CGSize) throws
    func render(device: MTLDevice, state: inout State, drawableSize: SIMD2<Float>, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) throws
    func encode(device: MTLDevice, state: inout State, drawableSize: SIMD2<Float>, commandEncoder: MTLRenderCommandEncoder) throws
}

// MARK: -

public protocol GeneralPassProtocol: PassProtocol {
    associatedtype State: PassState
    func setup(device: MTLDevice) throws -> State
    func encode(device: MTLDevice, state: inout State, commandBuffer: MTLCommandBuffer) throws // TODO: Rename
}

// MARK: -

public protocol GroupPassProtocol: PassProtocol {
    func children() throws -> [any PassProtocol]
}
