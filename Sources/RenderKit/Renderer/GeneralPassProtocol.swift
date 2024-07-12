import Metal

public protocol GeneralPassProtocol: PassProtocol {
    func setup(device: MTLDevice) throws -> State
    func encode(device: MTLDevice, state: inout State, commandBuffer: MTLCommandBuffer) throws // TODO: Rename
}

internal extension GeneralPassProtocol {
    // TODO: Rename
    func encode(device: MTLDevice, untypedState: inout any PassState, commandBuffer: MTLCommandBuffer) throws {
        guard var state = untypedState as? State else {
            fatalError()
        }
        try encode(device: device, state: &state, commandBuffer: commandBuffer)
        untypedState = state
    }
}
