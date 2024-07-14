import Metal

internal extension GeneralPassProtocol {
    func encode(untypedState: inout any PassState, commandBuffer: MTLCommandBuffer) throws {
        guard var state = untypedState as? State else {
            fatalError()
        }
        try encode(state: &state, commandBuffer: commandBuffer)
        untypedState = state
    }
}
