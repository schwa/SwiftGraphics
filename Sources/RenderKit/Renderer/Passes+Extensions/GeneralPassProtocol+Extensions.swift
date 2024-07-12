import Metal

internal extension GeneralPassProtocol {
    func encode(device: MTLDevice, untypedState: inout any PassState, commandBuffer: MTLCommandBuffer) throws {
        guard var state = untypedState as? State else {
            fatalError()
        }
        try encode(device: device, state: &state, commandBuffer: commandBuffer)
        untypedState = state
    }
}
