#if !targetEnvironment(simulator)
import BaseSupport
@preconcurrency import MetalFX

public struct SpatialUpscalingPass: GeneralPassProtocol {
    public struct State: Sendable {
    }

    public var id: PassID
    internal var spatialScaler: Box<MTLFXSpatialScaler>

    public init(id: PassID = .init(Self.self), device: MTLDevice, source: MTLTexture, destination: MTLTexture, colorProcessingMode: MTLFXSpatialScalerColorProcessingMode) throws {
        self.id = id

        // TODO: We are doing this in init() when it really should happen in setup() because we can't easily cause a new setup if texture size changes.
        let spatialScalerDescriptor = MTLFXSpatialScalerDescriptor()
        spatialScalerDescriptor.inputWidth = source.width
        spatialScalerDescriptor.inputHeight = source.height
        spatialScalerDescriptor.outputWidth = destination.width
        spatialScalerDescriptor.outputHeight = destination.height
        spatialScalerDescriptor.colorTextureFormat = source.pixelFormat
        spatialScalerDescriptor.outputTextureFormat = destination.pixelFormat
        spatialScalerDescriptor.colorProcessingMode = colorProcessingMode

        let spatialScaler = try spatialScalerDescriptor.makeSpatialScaler(device: device).safelyUnwrap(BaseError.resourceCreationFailure)
        spatialScaler.colorTexture = source
        spatialScaler.outputTexture = destination
        self.spatialScaler = .init(spatialScaler)
    }

    public func setup(device: MTLDevice) throws -> State {
        State()
    }

    public func encode(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws {
        spatialScaler().encode(commandBuffer: commandBuffer)
    }
}
#endif
