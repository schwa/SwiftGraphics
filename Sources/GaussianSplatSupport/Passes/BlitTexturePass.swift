import BaseSupport
import Metal
import RenderKit

struct BlitTexturePass: GeneralPassProtocol {
    let id: AnyHashable

    struct State: PassState {
    }

    let source: Box<MTLTexture>
    let destination: Box<MTLTexture>

    init(id: AnyHashable, source: MTLTexture, destination: MTLTexture) {
        self.id = id
        self.source = Box(source)
        self.destination = Box(destination)
    }

    func setup(device: MTLDevice) throws -> (State) {
        State()
    }

    func encode(device: MTLDevice, state: inout State, commandBuffer: MTLCommandBuffer) throws {
        let blitCommandEncoder = try commandBuffer.makeBlitCommandEncoder().safelyUnwrap(BaseError.generic("TODO")) // TODO: Sanitize error types.
        blitCommandEncoder.label = "BlitTexturePass(\(id))"
        blitCommandEncoder.copy(from: source(), to: destination())
        blitCommandEncoder.endEncoding()
    }
}
