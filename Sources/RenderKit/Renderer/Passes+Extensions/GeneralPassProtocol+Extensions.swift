import Metal

internal extension GeneralPassProtocol {
    func encode(commandBuffer: MTLCommandBuffer, info: PassInfo, untypedState: any PassState) throws {
        guard let state = untypedState as? State else {
            fatalError("Could not cast state to `State`, are two passes using same identifier?")
        }
        try encode(commandBuffer: commandBuffer, info: info, state: state)
    }
}
