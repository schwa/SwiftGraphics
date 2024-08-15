import BaseSupport
import Metal

internal extension GeneralPassProtocol {
    func encode(commandBuffer: MTLCommandBuffer, info: PassInfo, untypedState: any Sendable) throws {
        guard let state = untypedState as? State else {
            throw BaseError.error(.typeMismatch)
        }
        try encode(commandBuffer: commandBuffer, info: info, state: state)
    }
}
