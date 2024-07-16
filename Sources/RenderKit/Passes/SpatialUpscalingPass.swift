import BaseSupport
@preconcurrency import Metal
@preconcurrency import MetalFX

public struct SpatialUpscalingPass: GeneralPassProtocol {
    public struct State: PassState {
        var spatialScaler: MTLFXSpatialScaler
    }

    public var id: PassID
    public var spatialScalerDescriptor: MTLFXSpatialScalerDescriptor
    public var source: Box<MTLTexture>?
    public var destination: Box<MTLTexture>?
    public var colorProcessingMode: MTLFXSpatialScalerColorProcessingMode

    public init(id: PassID, inputSize: MTLSize, inputPixelFormat: MTLPixelFormat, outputSize: MTLSize, outputPixelFormat: MTLPixelFormat, colorProcessingMode: MTLFXSpatialScalerColorProcessingMode) {
        self.id = id
        spatialScalerDescriptor = MTLFXSpatialScalerDescriptor()
        spatialScalerDescriptor.inputWidth = inputSize.width
        spatialScalerDescriptor.inputHeight = inputSize.height
        spatialScalerDescriptor.outputWidth = outputSize.width
        spatialScalerDescriptor.outputHeight = outputSize.height
        spatialScalerDescriptor.colorTextureFormat = inputPixelFormat
        spatialScalerDescriptor.outputTextureFormat = outputPixelFormat
        spatialScalerDescriptor.colorProcessingMode = colorProcessingMode
        self.colorProcessingMode = colorProcessingMode
    }

    public func setup(device: MTLDevice) throws -> State {
        let spatialScaler = try spatialScalerDescriptor.makeSpatialScaler(device: device).safelyUnwrap(BaseError.resourceCreationFailure)
        return State(spatialScaler: spatialScaler)
    }

    public func encode(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws {
        guard let source = source?() else {
            fatalError()
        }
        guard let destination = destination?() ?? info.currentRenderPassDescriptor?.colorAttachments[0].texture else {
            fatalError("No destination")
        }
        print(spatialScalerDescriptor.inputWidth, spatialScalerDescriptor.inputHeight)
        print(spatialScalerDescriptor.outputWidth, spatialScalerDescriptor.outputHeight)
        assert(source !== destination)
        print(destination.storageMode.rawValue)
        state.spatialScaler.colorTexture = source
        state.spatialScaler.outputTexture = destination
        state.spatialScaler.encode(commandBuffer: commandBuffer)
    }
}

extension SpatialUpscalingPass {
    public init(id: PassID, source: MTLTexture, outputSize: MTLSize, outputPixelFormat: MTLPixelFormat, colorProcessingMode: MTLFXSpatialScalerColorProcessingMode) {
        self.init(id: id, inputSize: source.size, inputPixelFormat: source.pixelFormat, outputSize: outputSize, outputPixelFormat: outputPixelFormat, colorProcessingMode: colorProcessingMode)
        self.source = .init(source)
    }

    public init(id: PassID, source: MTLTexture, destination: MTLTexture, colorProcessingMode: MTLFXSpatialScalerColorProcessingMode) {
        self.init(id: id, inputSize: source.size, inputPixelFormat: source.pixelFormat, outputSize: destination.size, outputPixelFormat: destination.pixelFormat, colorProcessingMode: colorProcessingMode)
        self.source = .init(source)
        self.destination = .init(destination)
    }
}
