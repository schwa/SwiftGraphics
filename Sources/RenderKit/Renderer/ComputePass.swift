import Metal

protocol ComputePassProtocol: PassProtocol {
    func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLComputePipelineDescriptor) throws -> State
    func render(device: MTLDevice, state: State, passDescriptor: MTLComputePassDescriptor, commandBuffer: MTLCommandBuffer) throws
}
