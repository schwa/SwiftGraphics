import Metal

protocol ComputePassProtocol: Equatable, Sendable {
    associatedtype State: PassState
    var id: AnyHashable { get }
    func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLComputePipelineDescriptor) throws -> State
    func render(device: MTLDevice, state: State, passDescriptor: MTLComputePassDescriptor, commandBuffer: MTLCommandBuffer) throws
}
