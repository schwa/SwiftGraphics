import BaseSupport
import Metal
import RenderKit
import MetalFX

struct SpatialUpscalingPass: GeneralPassProtocol {
    struct State: PassState {
        var spatialScaler: MTLFXSpatialScaler
    }

    var id: AnyHashable
    var inputTexture: Box<MTLTexture>
    var outputTexture: Box<MTLTexture>
    var colorProcessingMode: MTLFXSpatialScalerColorProcessingMode

    init(id: AnyHashable, inputTexture: MTLTexture, outputTexture: MTLTexture, colorProcessingMode: MTLFXSpatialScalerColorProcessingMode) {
        self.id = id
        self.inputTexture = Box(inputTexture)
        self.outputTexture = Box(outputTexture)
        self.colorProcessingMode = colorProcessingMode
    }

    func setup(device: MTLDevice) throws -> State {
        let spatialScalerDescriptor = MTLFXSpatialScalerDescriptor()
        spatialScalerDescriptor.inputWidth = inputTexture().width
        spatialScalerDescriptor.inputHeight = inputTexture().height
        spatialScalerDescriptor.outputWidth = outputTexture().width
        spatialScalerDescriptor.outputHeight = outputTexture().height
        spatialScalerDescriptor.colorTextureFormat = inputTexture().pixelFormat
        spatialScalerDescriptor.outputTextureFormat = outputTexture().pixelFormat
        spatialScalerDescriptor.colorProcessingMode = colorProcessingMode

        let spatialScaler = try spatialScalerDescriptor.makeSpatialScaler(device: device).safelyUnwrap(BaseError.generic("OOPS"))
        spatialScaler.colorTexture = inputTexture.content
        spatialScaler.outputTexture = outputTexture.content

        return State(spatialScaler: spatialScaler)
    }

    func encode(device: MTLDevice, state: inout State, commandBuffer: MTLCommandBuffer) throws {
        state.spatialScaler.encode(commandBuffer: commandBuffer)
    }
}
