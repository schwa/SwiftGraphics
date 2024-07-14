import Metal

internal extension ComputePassProtocol {
    func compute(untypedState: inout any PassState, commandBuffer: MTLCommandBuffer) throws {
        guard var state = untypedState as? State else {
            fatalError()
        }
        try compute(commandBuffer: commandBuffer, state: &state)
        untypedState = state
    }
}

public extension ComputePassProtocol {
    func computeOnce(device: MTLDevice) throws {
        var state = try setup(device: device)
        let commandQueue = device.makeCommandQueue().forceUnwrap()
        let commandBuffer = commandQueue.makeCommandBuffer( ).forceUnwrap()
        try compute(commandBuffer: commandBuffer, state: &state)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
