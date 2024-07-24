import Metal

internal extension ComputePassProtocol {
    func compute(commandBuffer: MTLCommandBuffer, info: PassInfo, untypedState: PassState) throws {
        guard let state = untypedState as? State else {
            fatalError("Could not cast state to `State`, are two passes using same identifier?")
        }
        try compute(commandBuffer: commandBuffer, info: info, state: state)
    }
}

public extension ComputePassProtocol {
    @discardableResult
    func computeOnce(device: MTLDevice) throws -> State {
        let state = try setup(device: device)
        let commandQueue = device.makeCommandQueue().forceUnwrap()
        try commandQueue.withCommandBuffer(waitAfterCommit: true) { commandBuffer in
            let now = Date.now.timeIntervalSince1970
            let configuration = OffscreenRenderPassConfiguration()
            let info = PassInfo(drawableSize: .zero, frame: 0, start: now, time: now, deltaTime: 0, configuration: configuration)
            try compute(commandBuffer: commandBuffer, info: info, state: state)
        }
        return state
    }
}
