import Metal

internal extension ComputePassProtocol {
    func compute(commandBuffer: MTLCommandBuffer, info: PassInfo, untypedState: inout any PassState) throws {
        guard var state = untypedState as? State else {
            fatalError()
        }
        try compute(commandBuffer: commandBuffer, info: info, state: &state)
        untypedState = state
    }
}

public extension ComputePassProtocol {
    func computeOnce(device: MTLDevice) throws {
        var state = try setup(device: device)
        let commandQueue = device.makeCommandQueue().forceUnwrap()
        let commandBuffer = commandQueue.makeCommandBuffer( ).forceUnwrap()
        let now = Date.now.timeIntervalSince1970
        let info = PassInfo(drawableSize: .zero, frame: 0, start: now, time: now, deltaTime: 0)
        try compute(commandBuffer: commandBuffer, info: info, state: &state)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
