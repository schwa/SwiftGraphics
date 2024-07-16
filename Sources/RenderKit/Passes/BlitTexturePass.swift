import BaseSupport
@preconcurrency import Metal

public struct BlitTexturePass: GeneralPassProtocol {
    public struct State: PassState {
    }

    public var id: PassID
    public var source: Box<MTLTexture>
    public var destination: Box<MTLTexture>?

    public init(id: PassID, source: MTLTexture, destination: MTLTexture?) {
        self.id = id
        self.source = Box(source)
        self.destination = destination.map { Box($0) }
    }

    public func setup(device: MTLDevice) throws -> (State) {
        State()
    }

    public func encode(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws {

        let source = source()
        guard let destination = destination?() ?? info.currentRenderPassDescriptor?.colorAttachments[0].texture else {
            fatalError("No destination")
        }
        assert(source !== destination)

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
