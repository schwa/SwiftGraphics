import BaseSupport
@preconcurrency import Metal

public struct BlitTexturePass: GeneralPassProtocol {
    public struct State: Sendable {
    }

    public var id: PassID
    public var enabled: Bool = true

    public var source: Box<MTLTexture>
    public var destination: Box<MTLTexture>?

    public init(id: PassID, enabled: Bool = true, source: MTLTexture, destination: MTLTexture?) {
        self.id = id
        self.enabled = enabled
        self.source = Box(source)
        self.destination = destination.map { Box($0) }
    }

    public func setup(device: MTLDevice) throws -> (State) {
        State()
    }

    public func encode(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws {
        let source = source()
        guard let destination = destination?() ?? info.currentRenderPassDescriptor?.colorAttachments[0].texture else {
            throw BaseError.error(.invalidParameter)
        }
        guard source !== destination else {
            throw BaseError.error(.generic("Trying to blit to itself"))
        }
        guard source.size.width <= destination.size.width && source.size.height <= destination.size.height && source.size.depth <= destination.size.depth else {
            // NOTE: this is not quite accurate: "(destinationOrigin.x + destinationSize.width) must be <= width. (destinationOrigin.y + destinationSize.height) must be <= height."
            // throw BaseError.error(.generic("Trying to blit between (smaller) source of size \(source.size) & destination of size \(destination.size)"))
            return
        }

        let blitCommandEncoder = try commandBuffer.makeBlitCommandEncoder().safelyUnwrap(BaseError.resourceCreationFailure)
        blitCommandEncoder.label = "BlitTexturePass(\(id))"

        blitCommandEncoder.copy(from: source,
                                sourceSlice: 0,
                                sourceLevel: 0,
                                sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                                sourceSize: MTLSize(source.width, source.height, source.depth),
                                to: destination,
                                destinationSlice: 0,
                                destinationLevel: 0,
                                destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))

        blitCommandEncoder.endEncoding()
    }
}
