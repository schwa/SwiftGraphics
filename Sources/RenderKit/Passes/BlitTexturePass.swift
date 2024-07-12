import BaseSupport
import Metal

public struct BlitTexturePass: GeneralPassProtocol {
    public struct State: PassState {
    }

    public var id: AnyHashable
    public var source: Box<MTLTexture>
    public var destination: Box<MTLTexture>

    public init(id: AnyHashable, source: MTLTexture, destination: MTLTexture) {
        self.id = id
        self.source = Box(source)
        self.destination = Box(destination)
    }

    public func setup(device: MTLDevice) throws -> (State) {
        State()
    }

    public func encode(device: MTLDevice, state: inout State, commandBuffer: MTLCommandBuffer) throws {
        let blitCommandEncoder = try commandBuffer.makeBlitCommandEncoder().safelyUnwrap(BaseError.resourceCreationFailure)
        blitCommandEncoder.label = "BlitTexturePass(\(id))"
        blitCommandEncoder.copy(from: source(), to: destination())
        blitCommandEncoder.endEncoding()
    }
}
