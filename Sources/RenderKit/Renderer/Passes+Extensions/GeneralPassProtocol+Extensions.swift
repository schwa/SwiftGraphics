import Metal

internal extension GeneralPassProtocol {
    func encode(commandBuffer: MTLCommandBuffer, info: PassInfo, untypedState: inout any PassState) throws {
        guard var state = untypedState as? State else {
            fatalError()
        }
        try encode(commandBuffer: commandBuffer, info: info, state: &state)
        untypedState = state
    }
}
