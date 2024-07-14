import BaseSupport
import Metal
import MetalFX

public struct SpatialUpscalingPass: GeneralPassProtocol {
    public struct State: PassState {
        var spatialScaler: MTLFXSpatialScaler
    }

    public var id: AnyHashable
    public var inputTexture: Box<MTLTexture>
    public var outputTexture: Box<MTLTexture>
    public var colorProcessingMode: MTLFXSpatialScalerColorProcessingMode

    public init(id: AnyHashable, inputTexture: MTLTexture, outputTexture: MTLTexture, colorProcessingMode: MTLFXSpatialScalerColorProcessingMode) {
        self.id = id
        self.inputTexture = Box(inputTexture)
        self.outputTexture = Box(outputTexture)
        self.colorProcessingMode = colorProcessingMode
    }

    public func setup(device: MTLDevice) throws -> State {
        let spatialScalerDescriptor = MTLFXSpatialScalerDescriptor()
        spatialScalerDescriptor.inputWidth = inputTexture().width
        spatialScalerDescriptor.inputHeight = inputTexture().height
        spatialScalerDescriptor.outputWidth = outputTexture().width
        spatialScalerDescriptor.outputHeight = outputTexture().height
        spatialScalerDescriptor.colorTextureFormat = inputTexture().pixelFormat
        spatialScalerDescriptor.outputTextureFormat = outputTexture().pixelFormat
        spatialScalerDescriptor.colorProcessingMode = colorProcessingMode

        let spatialScaler = try spatialScalerDescriptor.makeSpatialScaler(device: device).safelyUnwrap(BaseError.resourceCreationFailure)
        spatialScaler.colorTexture = inputTexture.content
        spatialScaler.outputTexture = outputTexture.content

        return State(spatialScaler: spatialScaler)
    }

    public func encode(commandBuffer: MTLCommandBuffer, state: inout State) throws {
        state.spatialScaler.encode(commandBuffer: commandBuffer)
    }
}
