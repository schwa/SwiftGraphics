//
//  File.swift
//  SwiftGraphics
//
//  Created by Jonathan Wight on 7/12/24.
//


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
