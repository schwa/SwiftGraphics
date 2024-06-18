import Metal

public protocol ComputePassProtocol: PassProtocol {
    func setup(device: MTLDevice) throws -> State
    func compute(device: MTLDevice, state: State, commandBuffer: MTLCommandBuffer) throws
}

public extension ComputePassProtocol {
    func compute(device: MTLDevice, untypedState: any PassState, commandBuffer: MTLCommandBuffer) throws {
        guard let state = untypedState as? State else {
            fatalError()
        }
        try compute(device: device, state: state, commandBuffer: commandBuffer)
    }
}
