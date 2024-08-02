import BaseSupport
import CoreGraphics
import CoreGraphicsSupport
import Metal
import MetalKit
import MetalPerformanceShaders

public extension MTLTexture {
    func convert(pixelFormat: MTLPixelFormat, destinationColorSpace: CGColorSpace, sourceAlpha: MPSAlphaType, destinationAlpha: MPSAlphaType) throws -> MTLTexture {
        guard let sourceColorSpace = pixelFormat.colorSpace else {
            throw BaseError.illegalValue
        }
        let destinationTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
        destinationTextureDescriptor.usage = [.shaderRead, .shaderWrite]
        guard let destinationTexture = device.makeTexture(descriptor: destinationTextureDescriptor) else {
            throw BaseError.resourceCreationFailure
        }
        let conversionInfo = CGColorConversionInfo(src: sourceColorSpace, dst: destinationColorSpace)
        let conversion = MPSImageConversion(device: device, srcAlpha: sourceAlpha, destAlpha: destinationAlpha, backgroundColor: nil, conversionInfo: conversionInfo)
        let commandQueue = device.makeCommandQueue().forceUnwrap("Could not create command queue")
        let commandBuffer = commandQueue.makeCommandBuffer().forceUnwrap("Could not create command buffer")
        conversion.encode(commandBuffer: commandBuffer, sourceTexture: self, destinationTexture: destinationTexture)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        return destinationTexture
    }

    func histogram() -> MTLBuffer {
        let filter = MPSImageHistogram(device: device)
        let size = filter.histogramSize(forSourceFormat: pixelFormat)
        guard let histogram = device.makeBuffer(length: size) else {
            fatalError(BaseError.resourceCreationFailure)
        }
        let commandQueue = device.makeCommandQueue().forceUnwrap("Failed to create command queue")
        let commandBuffer = commandQueue.makeCommandBuffer().forceUnwrap("Failed to create command buffer")
        filter.encode(to: commandBuffer, sourceTexture: self, histogram: histogram, histogramOffset: 0)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        return histogram
    }

    func cgImage(colorSpace: CGColorSpace? = nil) throws -> CGImage {
        if let pixelFormat = PixelFormat(pixelFormat) {
            let bitmapDefinition = BitmapDefinition(width: width, height: height, pixelFormat: pixelFormat)
            let context = try CGContext.bitmapContext(definition: bitmapDefinition)
            assert(context.bytesPerRow == bitmapDefinition.bytesPerRow)
            guard let pixelBytes = context.data else {
                throw BaseError.resourceCreationFailure
            }
            getBytes(pixelBytes, bytesPerRow: bitmapDefinition.bytesPerRow, from: MTLRegion(origin: .zero, size: MTLSize(width, height, 1)), mipmapLevel: 0)
            guard let image = context.makeImage() else {
                throw BaseError.resourceCreationFailure
            }
            return image
        }
        //            // https://developer.apple.com/documentation/metal/mtltexture/1515598-newtextureviewwithpixelformat
        else {
            guard let srcColorSpace = pixelFormat.colorSpace else {
                throw BaseError.invalidParameter
            }
            guard let dstColorSpace = colorSpace else {
                throw BaseError.invalidParameter
            }
            let destinationTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: width, height: height, mipmapped: false)
            destinationTextureDescriptor.usage = [.shaderRead, .shaderWrite]
            guard let destinationTexture = device.makeTexture(descriptor: destinationTextureDescriptor) else {
                throw BaseError.resourceCreationFailure
            }
            let conversionInfo = CGColorConversionInfo(src: srcColorSpace, dst: dstColorSpace)
            // TODO: we're just assuming premultiplied here.
            let conversion = MPSImageConversion(device: device, srcAlpha: .premultiplied, destAlpha: .premultiplied, backgroundColor: nil, conversionInfo: conversionInfo)
            let commandQueue = device.makeCommandQueue().forceUnwrap("Failed to create command queue")
            let commandBuffer = commandQueue.makeCommandBuffer().forceUnwrap("Failed to create command buffer")
            conversion.encode(commandBuffer: commandBuffer, sourceTexture: self, destinationTexture: destinationTexture)
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            return try destinationTexture.cgImage()
        }
    }
}
