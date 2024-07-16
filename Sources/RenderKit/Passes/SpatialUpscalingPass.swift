import BaseSupport
@preconcurrency import Metal
#if canImport(MetalFX)
@preconcurrency import MetalFX
#endif

public struct SpatialUpscalingPass: GeneralPassProtocol {
    public struct State: PassState {
        var spatialScaler: MTLFXSpatialScaler
    }

    public var id: PassID
    public var source: Box<MTLTexture>?
    public var destination: Box<MTLTexture>?
    public var spatialScalerDescriptor: MTLFXSpatialScalerDescriptor
    public var colorProcessingMode: MTLFXSpatialScalerColorProcessingMode

    public init(id: PassID, inputSize: MTLSize, inputPixelFormat: MTLPixelFormat, outputSize: MTLSize, outputPixelFormat: MTLPixelFormat, colorProcessingMode: MTLFXSpatialScalerColorProcessingMode) {
        self.id = id

        // TODO: This really needs to go into setup or size will change. Or just base it on textures.
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
            fatalError("No source")
        }
        guard let destination = destination?() ?? info.currentRenderPassDescriptor?.colorAttachments[0].texture else {
            fatalError("No destination")
        }
        print(spatialScalerDescriptor.inputWidth, spatialScalerDescriptor.inputHeight)
        print(spatialScalerDescriptor.outputWidth, spatialScalerDescriptor.outputHeight)
        print(info.currentRenderPassDescriptor?.colorAttachments[0].texture?.size)

        assert(source !== destination)
        state.spatialScaler.colorTexture = source
        state.spatialScaler.outputTexture = destination
        state.spatialScaler.encode(commandBuffer: commandBuffer)
    }
}

public extension SpatialUpscalingPass {
    init(id: PassID, source: MTLTexture, outputSize: MTLSize, outputPixelFormat: MTLPixelFormat, colorProcessingMode: MTLFXSpatialScalerColorProcessingMode) {
        self.init(id: id, inputSize: source.size, inputPixelFormat: source.pixelFormat, outputSize: outputSize, outputPixelFormat: outputPixelFormat, colorProcessingMode: colorProcessingMode)
        self.source = .init(source)
    }

    init(id: PassID, source: MTLTexture, destination: MTLTexture, colorProcessingMode: MTLFXSpatialScalerColorProcessingMode) {
        self.init(id: id, inputSize: source.size, inputPixelFormat: source.pixelFormat, outputSize: destination.size, outputPixelFormat: destination.pixelFormat, colorProcessingMode: colorProcessingMode)
        self.source = .init(source)
        self.destination = .init(destination)
    }
}
