import BaseSupport
import Metal

public struct BlitTexturePass: GeneralPassProtocol {
    public struct State: PassState {
    }

    public var id: PassID
    public var source: Box<MTLTexture>
    public var destination: Box<MTLTexture>

    public init(id: PassID, source: MTLTexture, destination: MTLTexture) {
        self.id = id
        self.source = Box(source)
        self.destination = Box(destination)
    }

    public func setup(device: MTLDevice) throws -> (State) {
        State()
    }

    public func encode(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws {
        let blitCommandEncoder = try commandBuffer.makeBlitCommandEncoder().safelyUnwrap(BaseError.resourceCreationFailure)
        blitCommandEncoder.label = "BlitTexturePass(\(id))"
        blitCommandEncoder.copy(from: source(), to: destination())
        blitCommandEncoder.endEncoding()
    }
}