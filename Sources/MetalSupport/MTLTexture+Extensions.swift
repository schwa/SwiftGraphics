import BaseSupport
import CoreGraphics
import CoreGraphicsSupport
import Metal
import MetalKit
import MetalPerformanceShaders

public extension MTLDevice {
    func newTexture(with image: CGImage, options: [MTKTextureLoader.Option: Any]? = nil) throws -> MTLTexture {
        // Through much annoying debugging I discovered MTKTextureLoader doesn't like CGImages with .orderDefault byte order.
        assert(image.byteOrderInfo != .orderDefault)
        return try MTKTextureLoader(device: self).newTexture(cgImage: image, options: options)
    }

    func newBufferFor2DTexture(pixelFormat: MTLPixelFormat, size: MTLSize) throws -> MTLBuffer {
        assert(size.depth == 1)
        let bytesPerPixel = pixelFormat.bits.forceUnwrap("Could not gets.") / 8
        let alignment = minimumLinearTextureAlignment(for: pixelFormat)
        let bytesPerRow = align(Int(size.width) * bytesPerPixel, alignment: alignment)
        guard let buffer = makeBuffer(length: bytesPerRow * Int(size.height), options: .storageModeShared) else {
            throw BaseError.resourceCreationFailure
        }
        return buffer
    }

    func makeColorTexture(size: CGSize, pixelFormat: MTLPixelFormat) throws -> MTLTexture {
        // Create a shared memory MTLBuffer for the color attachment texture. This allows us to access the pixels efficiently from CPU later on (which is likely the whole point of an offscreen renderer).
        let colorAttachmentTextureBuffer = try newBufferFor2DTexture(pixelFormat: pixelFormat, size: MTLSize(width: Int(size.width), height: Int(size.height), depth: 1))

        // Now create a texture descriptor and texture from the buffer
        let colorAttachmentTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: Int(size.width), height: Int(size.height), mipmapped: false)
        colorAttachmentTextureDescriptor.storageMode = .shared
        colorAttachmentTextureDescriptor.usage = [.renderTarget]

        let bytesPerPixel = pixelFormat.bits.forceUnwrap("Could not gets.") / 8
        let alignment = minimumLinearTextureAlignment(for: pixelFormat)
        let bytesPerRow = align(Int(size.width) * bytesPerPixel, alignment: alignment)
        let colorAttachmentTexture = try colorAttachmentTextureBuffer.makeTexture(descriptor: colorAttachmentTextureDescriptor, offset: 0, bytesPerRow: bytesPerRow).safelyUnwrap(BaseError.resourceCreationFailure)
        colorAttachmentTexture.label = "Color Texture"
        return colorAttachmentTexture
    }

    func makeDepthTexture(size: CGSize, depthStencilPixelFormat: MTLPixelFormat) throws -> MTLTexture {
        // ... and if we had a depth buffer - do the same... except depth buffers can be memoryless (yay) and we .dontCare about storing them later.
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: depthStencilPixelFormat, width: Int(size.width), height: Int(size.height), mipmapped: false)
        depthTextureDescriptor.storageMode = .memoryless
        depthTextureDescriptor.usage = .renderTarget
        let depthStencilTexture = try makeTexture(descriptor: depthTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        depthStencilTexture.label = "Depth Texture"
        return depthStencilTexture
    }

    /// "To copy your data to a private texture, copy your data to a temporary texture with non-private storage, and then use an MTLBlitCommandEncoder to copy the data to the private texture for GPU use."
    func makePrivateCopy(of source: MTLTexture) throws -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = source.textureType
        textureDescriptor.pixelFormat = source.pixelFormat
        textureDescriptor.storageMode = .private

        textureDescriptor.width = source.width
        textureDescriptor.height = source.height
        textureDescriptor.depth = source.depth
        guard let destination = makeTexture(descriptor: textureDescriptor) else {
            throw BaseError.resourceCreationFailure
        }
        destination.label = source.label.map { "\($0)-private-copy" }

        guard let commandQueue = makeCommandQueue() else {
            throw BaseError.resourceCreationFailure
        }
        try commandQueue.withCommandBuffer(waitAfterCommit: true) { commandBuffer in
            guard let encoder = commandBuffer.makeBlitCommandEncoder() else {
                throw BaseError.resourceCreationFailure
            }
            encoder.copy(from: source, to: destination)
            encoder.endEncoding()
        }
        return destination
    }
}

// MARK: -

public extension MTLTexture {
    var size: MTLSize {
        MTLSize(width, height, depth)
    }

    var region: MTLRegion {
        MTLRegion(origin: .zero, size: size)
    }

    func clear(color: SIMD4<UInt8> = [0, 0, 0, 0]) {
        assert(depth == 1)
        let buffer = Array(repeatElement(color, count: width * height * depth))
        assert(MemoryLayout<SIMD4<UInt8>>.stride == pixelFormat.size)
        buffer.withUnsafeBytes { pointer in
            let baseAddress = pointer.baseAddress.forceUnwrap("Could not get base address of buffer")
            replace(region: region, mipmapLevel: 0, withBytes: baseAddress, bytesPerRow: width * MemoryLayout<SIMD4<UInt8>>.stride)
        }
    }

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
}

// MARK: -

public extension MTLTextureDescriptor {
    convenience init(_ texture: MTLTexture) {
        self.init()
        textureType = texture.textureType
        pixelFormat = texture.pixelFormat
        width = texture.width
        height = texture.height
        depth = texture.depth
        mipmapLevelCount = texture.mipmapLevelCount
        sampleCount = texture.sampleCount
        arrayLength = texture.arrayLength
        resourceOptions = texture.resourceOptions
        cpuCacheMode = texture.cpuCacheMode
        storageMode = texture.storageMode
        hazardTrackingMode = texture.hazardTrackingMode
        usage = texture.usage
        allowGPUOptimizedContents = texture.allowGPUOptimizedContents
        compressionType = texture.compressionType
        swizzle = texture.swizzle
    }

    var bytesPerRow: Int? {
        pixelFormat.size.map { $0 * width }
    }
}
