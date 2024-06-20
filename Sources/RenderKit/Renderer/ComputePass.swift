import Metal

public protocol ComputePassProtocol: PassProtocol {
    func setup(device: MTLDevice) throws -> State
    func compute(device: MTLDevice, state: inout State, commandBuffer: MTLCommandBuffer) throws
}

internal extension ComputePassProtocol {
    func compute(device: MTLDevice, untypedState: inout any PassState, commandBuffer: MTLCommandBuffer) throws {
        guard var state = untypedState as? State else {
            fatalError()
        }
        try compute(device: device, state: &state, commandBuffer: commandBuffer)
        untypedState = state
    }
}
