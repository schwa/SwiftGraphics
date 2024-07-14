import Metal

internal extension GeneralPassProtocol {
    func encode(untypedState: inout any PassState, commandBuffer: MTLCommandBuffer) throws {
        guard var state = untypedState as? State else {
            fatalError()
        }
        try encode(commandBuffer: commandBuffer, state: &state)
        untypedState = state
    }
}
