//
//  File.swift
//  SwiftGraphics
//
//  Created by Jonathan Wight on 7/12/24.
//


internal extension ComputePassProtocol {
    func compute(device: MTLDevice, untypedState: inout any PassState, commandBuffer: MTLCommandBuffer) throws {
        guard var state = untypedState as? State else {
            fatalError()
        }
        try compute(device: device, state: &state, commandBuffer: commandBuffer)
        untypedState = state
    }
}

public extension ComputePassProtocol {
    func computeOnce(device: MTLDevice) throws {
        var state = try setup(device: device)
        let commandQueue = device.makeCommandQueue().forceUnwrap()
        let commandBuffer = commandQueue.makeCommandBuffer( ).forceUnwrap()
        try compute(device: device, state: &state, commandBuffer: commandBuffer)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
