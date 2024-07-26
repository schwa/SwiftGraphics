// swiftlint:disable file_length

import BaseSupport
import CoreGraphics
import CoreGraphicsSupport
import Foundation
import Metal
import MetalKit
import MetalPerformanceShaders
import ModelIO
import os
import simd

// TODO: This file is a mess.
// TODO: Take note of the deprecations here.

public extension MTKMesh {
    func labelBuffers(_ label: String) {
        for (index, buffer) in vertexBuffers.enumerated() {
            buffer.buffer.label = "\(label)-vertexBuffer#\(index)"
        }
        for (index, submesh) in submeshes.enumerated() {
            submesh.indexBuffer.buffer.label = "\(label)-indexBuffer#\(index)"
        }
    }
}

public extension MTLArgumentDescriptor {
    @available(iOS 17, macOS 14, *)
    convenience init(dataType: MTLDataType, index: Int, arrayLength: Int? = nil, access: MTLBindingAccess? = nil, textureType: MTLTextureType? = nil, constantBlockAlignment: Int? = nil) {
        self.init()
        self.dataType = dataType
        self.index = index
        if let arrayLength {
            self.arrayLength = arrayLength
        }
        if let access {
            self.access = access
        }
        if let textureType {
            self.textureType = textureType
        }
        if let constantBlockAlignment {
            self.arrayLength = constantBlockAlignment
        }
    }
}

public extension MTLAttributeDescriptor {
    convenience init(format: MTLAttributeFormat, offset: Int = 0, bufferIndex: Int) {
        self.init()
        self.format = format
        self.offset = offset
        self.bufferIndex = bufferIndex
    }
}

public extension MTLBuffer {
    func data() -> Data {
        Data(bytes: contents(), count: length)
    }

    /// Update a MTLBuffer's contents using an inout type block
    func with<T, R>(type: T.Type, _ block: (inout T) -> R) -> R {
        let value = contents().bindMemory(to: T.self, capacity: 1)
        return block(&value.pointee)
    }

    func withEx<T, R>(type: T.Type, count: Int, _ block: (UnsafeMutableBufferPointer<T>) -> R) -> R {
        let pointer = contents().bindMemory(to: T.self, capacity: count)
        let buffer = UnsafeMutableBufferPointer(start: pointer, count: count)
        return block(buffer)
    }

    func contentsBuffer() -> UnsafeMutableRawBufferPointer {
        UnsafeMutableRawBufferPointer(start: contents(), count: length)
    }

    func contentsBuffer<T>(of type: T.Type) -> UnsafeMutableBufferPointer<T> {
        contentsBuffer().bindMemory(to: type)
    }
    func labelled(_ label: String) -> MTLBuffer {
        self.label = label
        return self
    }
}

public extension MTLCommandBuffer {
    func withRenderCommandEncoder<R>(descriptor: MTLRenderPassDescriptor, label: String? = nil, useDebugGroup: Bool = false, block: (MTLRenderCommandEncoder) throws -> R) throws -> R {
        guard let renderCommandEncoder = makeRenderCommandEncoder(descriptor: descriptor) else {
            throw BaseError.resourceCreationFailure
        }
        if let label {
            renderCommandEncoder.label = label
        }
        defer {
            renderCommandEncoder.endEncoding()
        }
        return try renderCommandEncoder.withDebugGroup("Encode \(label ?? "RenderCommandEncoder")", enabled: useDebugGroup) {
            try block(renderCommandEncoder)
        }
    }
}

public extension MTLCommandEncoder {
    func withDebugGroup<R>(_ string: String, enabled: Bool = true, _ closure: () throws -> R) rethrows -> R {
        if enabled {
            pushDebugGroup(string)
        }
        defer {
            if enabled {
                popDebugGroup()
            }
        }
        return try closure()
    }
}

public extension MTLCommandQueue {
    func withCommandBuffer<R>(descriptor: MTLCommandBufferDescriptor? = nil, waitAfterCommit wait: Bool, block: (MTLCommandBuffer) throws -> R) throws -> R {
        let descriptor = descriptor ?? .init()
        guard let commandBuffer = makeCommandBuffer(descriptor: descriptor) else {
            throw BaseError.resourceCreationFailure
        }
        defer {
            commandBuffer.commit()
            if wait {
                commandBuffer.waitUntilCompleted()
            }
        }
        return try block(commandBuffer)
    }

    func withCommandBuffer<R>(drawable: (any MTLDrawable)? = nil, block: (MTLCommandBuffer) throws -> R) throws -> R {
        guard let commandBuffer = makeCommandBuffer() else {
            throw BaseError.resourceCreationFailure
        }
        defer {
            if let drawable {
                commandBuffer.present(drawable)
            }
            commandBuffer.commit()
        }
        return try block(commandBuffer)
    }
}

public extension MTLDepthStencilDescriptor {
    convenience init(depthCompareFunction: MTLCompareFunction, isDepthWriteEnabled: Bool) {
        self.init()
        self.depthCompareFunction = depthCompareFunction
        self.isDepthWriteEnabled = isDepthWriteEnabled
    }
}

public extension MTLDevice {
    func capture <R>(enabled: Bool = true, _ block: () throws -> R) throws -> R {
        guard enabled else {
            return try block()
        }
        let captureManager = MTLCaptureManager.shared()
        let captureScope = captureManager.makeCaptureScope(device: self)
        let captureDescriptor = MTLCaptureDescriptor()
        captureDescriptor.captureObject = captureScope
        try captureManager.startCapture(with: captureDescriptor)
        captureScope.begin()
        defer {
            captureScope.end()
        }
        return try block()
    }

    // TODO: Rename
    func makeBufferEx(bytes pointer: UnsafeRawPointer, length: Int, options: MTLResourceOptions = []) throws -> MTLBuffer {
        guard let buffer = makeBuffer(bytes: pointer, length: length, options: options) else {
            throw BaseError.resourceCreationFailure
        }
        return buffer
    }

    // TODO: Rename
    func makeBufferEx(length: Int, options: MTLResourceOptions = []) throws -> MTLBuffer {
        guard let buffer = makeBuffer(length: length, options: options) else {
            throw BaseError.resourceCreationFailure
        }
        return buffer
    }

    func makeBuffer(data: Data, options: MTLResourceOptions) throws -> MTLBuffer {
        try data.withUnsafeBytes { buffer in
            let baseAddress = buffer.baseAddress.forceUnwrap("No baseAddress.")
            guard let buffer = makeBuffer(bytes: baseAddress, length: buffer.count, options: options) else {
                throw BaseError.resourceCreationFailure
            }
            return buffer
        }
    }

    func makeBuffer(bytesOf content: some Any, options: MTLResourceOptions) throws -> MTLBuffer {
        try withUnsafeBytes(of: content) { buffer in
            let baseAddress = buffer.baseAddress.forceUnwrap("No baseAddress.")
            guard let buffer = makeBuffer(bytes: baseAddress, length: buffer.count, options: options) else {
                throw BaseError.resourceCreationFailure
            }
            return buffer
        }
    }

    func makeBuffer(bytesOf content: [some Any], options: MTLResourceOptions) throws -> MTLBuffer {
        try content.withUnsafeBytes { buffer in
            let baseAddress = buffer.baseAddress.forceUnwrap("No baseAddress.")
            guard let buffer = makeBuffer(bytes: baseAddress, length: buffer.count, options: options) else {
                throw BaseError.resourceCreationFailure
            }
            return buffer
        }
    }

    var supportsNonuniformThreadGroupSizes: Bool {
        let families: [MTLGPUFamily] = [.apple4, .apple5, .apple6, .apple7]
        return families.contains { supportsFamily($0) }
    }

    func newTexture(with image: CGImage, options: [MTKTextureLoader.Option: Any]? = nil) throws -> MTLTexture {
        // Through much annoying debugging I discovered MTKTextureLoader doesn't like CGImages with .orderDefault byte order.
        assert(image.byteOrderInfo != .orderDefault)
        return try MTKTextureLoader(device: self).newTexture(cgImage: image, options: options)
    }

    func makeDebugLibrary(bundle: Bundle) throws -> MTLLibrary {
        if let url = bundle.url(forResource: "debug", withExtension: "metallib") {
            return try makeLibrary(URL: url)
        }
        else {
            // TODO: Logger()
            Logger().warning("Failed to load debug metal library, falling back to bundle's default library.")
            return try makeDefaultLibrary(bundle: bundle)
        }
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

    func makeComputePipelineState(function: MTLFunction, options: MTLPipelineOption) throws -> (MTLComputePipelineState, MTLComputePipelineReflection?) {
        var reflection: MTLComputePipelineReflection?
        let pipelineState = try makeComputePipelineState(function: function, options: options, reflection: &reflection)
        return (pipelineState, reflection)
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

public extension MTLFunctionConstantValues {
    convenience init(dictionary: [Int: Any]) {
        self.init()

        for (index, value) in dictionary {
            withUnsafeBytes(of: value) { buffer in
                let baseAddress = buffer.baseAddress.forceUnwrap("Could not get base Address")
                setConstantValue(baseAddress, type: .bool, index: index)
            }
        }
    }

    func setConstantValue(_ value: Bool, index: Int) {
        withUnsafeBytes(of: value) { buffer in
            let baseAddress = buffer.baseAddress.forceUnwrap("Could not get base Address")
            setConstantValue(baseAddress, type: .bool, index: index)
        }
    }
}

public extension MTLIndexType {
    var indexSize: Int {
        switch self {
        case .uint16:
            MemoryLayout<UInt16>.size
        case .uint32:
            MemoryLayout<UInt32>.size
        default:
            fatalError(BaseError.illegalValue)
        }
    }
}

public extension MTLPrimitiveType {
    var vertexCount: Int? {
        switch self {
        case .triangle:
            3
        default:
            fatalError(BaseError.illegalValue)
        }
    }
}

public extension MTLRenderCommandEncoder {
    func withDebugGroup<R>(_ string: String, block: () throws -> R) rethrows -> R {
        pushDebugGroup(string)
        defer {
            popDebugGroup()
        }
        return try block()
    }

    // @available(*, deprecated, message: "Deprecated. Clean this up.")
    func setVertexBuffersFrom(mesh: MTKMesh) {
        for (index, element) in mesh.vertexDescriptor.layouts.enumerated() {
            guard let layout = element as? MDLVertexBufferLayout else {
                return
            }
            // TODO: Is this a reliable test on any vertex descriptor?
            if layout.stride != 0 {
                let buffer = mesh.vertexBuffers[index]
                setVertexBuffer(buffer.buffer, offset: buffer.offset, index: index)
            }
        }
    }

    // @available(*, deprecated, message: "Deprecated. Clean this up.")
    func draw(_ mesh: MTKMesh, setVertexBuffers: Bool = true) {
        if setVertexBuffers {
            for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
                setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: index)
            }
        }
        for submesh in mesh.submeshes {
            drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        }
    }

    // @available(*, deprecated, message: "Deprecated. Clean this up.")
    func draw(_ mesh: MTKMesh, instanceCount: Int) {
        for submesh in mesh.submeshes {
            drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset, instanceCount: instanceCount)
        }
    }

    // @available(*, deprecated, message: "Deprecated. Clean this up.")
    func setVertexBuffer(_ mesh: MTKMesh, startingIndex: Int) {
        for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
            setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: startingIndex + index)
        }
    }
}

public extension MTLTexture {
    var size: MTLSize {
        MTLSize(width, height, depth)
    }

    var region: MTLRegion {
        MTLRegion(origin: .zero, size: size)
    }

    func clear(color: SIMD4<UInt8> = [0, 0, 0, 0]) {
        // TODO: This is crazy expensive. :-)
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

public extension MTLVertexDescriptor {
    convenience init(vertexDescriptor: MDLVertexDescriptor) {
        self.init()
        for (index, mdlAttribute) in vertexDescriptor.attributes.enumerated() {
            // swiftlint:disable:next force_cast
            let mdlAttribute = mdlAttribute as! MDLVertexAttribute
            attributes[index].offset = mdlAttribute.offset
            attributes[index].bufferIndex = mdlAttribute.bufferIndex
            attributes[index].format = MTLVertexFormat(mdlAttribute.format)
        }
        for (index, mdlLayout) in vertexDescriptor.layouts.enumerated() {
            // swiftlint:disable:next force_cast
            let mdlLayout = mdlLayout as! MDLVertexBufferLayout
            layouts[index].stride = mdlLayout.stride
        }
    }
}

public extension MTLVertexFormat {
    var size: Int {
        switch self {
        case .uchar, .ucharNormalized:
            return MemoryLayout<UInt8>.size
        case .uchar2, .uchar2Normalized:
            return 2 * MemoryLayout<UInt8>.size
        case .uchar3, .uchar3Normalized:
            return 3 * MemoryLayout<UInt8>.size
        case .uchar4, .uchar4Normalized:
            return 4 * MemoryLayout<UInt8>.size
        case .char, .charNormalized:
            return MemoryLayout<Int8>.size
        case .char2, .char2Normalized:
            return 2 * MemoryLayout<Int8>.size
        case .char3, .char3Normalized:
            return 3 * MemoryLayout<Int8>.size
        case .char4, .char4Normalized:
            return 4 * MemoryLayout<Int8>.size
        case .ushort, .ushortNormalized:
            return MemoryLayout<UInt16>.size
        case .ushort2, .ushort2Normalized:
            return 2 * MemoryLayout<UInt16>.size
        case .ushort3, .ushort3Normalized:
            return 3 * MemoryLayout<UInt16>.size
        case .ushort4, .ushort4Normalized:
            return 4 * MemoryLayout<UInt16>.size
        case .short, .shortNormalized:
            return MemoryLayout<Int16>.size
        case .short2, .short2Normalized:
            return 2 * MemoryLayout<Int16>.size
        case .short3, .short3Normalized:
            return 3 * MemoryLayout<Int16>.size
        case .short4, .short4Normalized:
            return 4 * MemoryLayout<Int16>.size
        case .half:
            #if arch(arm64)
            return MemoryLayout<Float16>.size
            #else
            return MemoryLayout<Int16>.size
            #endif
        case .half2:
            #if arch(arm64)
            return 2 * MemoryLayout<Float16>.size
            #else
            return 2 * MemoryLayout<Int16>.size
            #endif
        case .half3:
            #if arch(arm64)
            return 3 * MemoryLayout<Float16>.size
            #else
            return 3 * MemoryLayout<Int16>.size
            #endif
        case .half4:
            #if arch(arm64)
            return MemoryLayout<Float16>.size
            #else
            return MemoryLayout<Int16>.size
            #endif
        case .float:
            return MemoryLayout<Float>.size
        case .float2:
            return 2 * MemoryLayout<Float>.size
        case .float3:
            return 3 * MemoryLayout<Float>.size
        case .float4:
            return 4 * MemoryLayout<Float>.size
        case .int:
            return MemoryLayout<Int32>.size
        case .int2:
            return 2 * MemoryLayout<Int32>.size
        case .int3:
            return 3 * MemoryLayout<Int32>.size
        case .int4:
            return 4 * MemoryLayout<UInt32>.size
        case .uint:
            return MemoryLayout<UInt32>.size
        case .uint2:
            return 2 * MemoryLayout<UInt32>.size
        case .uint3:
            return 3 * MemoryLayout<UInt32>.size
        case .uint4:
            return 4 * MemoryLayout<UInt32>.size
        case .int1010102Normalized, .uint1010102Normalized:
            return MemoryLayout<UInt32>.size
        case .uchar4Normalized_bgra:
            return 4 * MemoryLayout<UInt8>.size
        default:
            fatalError("Unknown MTLVertexFormat \(self)")
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    init?(dataType: MTLDataType) {
        switch dataType {
        case .float2:
            self = .float2
        case .float3:
            self = .float3
        case .float4:
            self = .float4
        case .half:
            self = .half
        case .half2:
            self = .half2
        case .half3:
            self = .half3
        case .half4:
            self = .half4
        case .int:
            self = .int
        case .int2:
            self = .int2
        case .int3:
            self = .int3
        case .int4:
            self = .int4
        case .uint:
            self = .uint
        case .uint2:
            self = .uint2
        case .uint3:
            self = .uint3
        case .uint4:
            self = .uint4
        case .short:
            self = .short
        case .short2:
            self = .short2
        case .short3:
            self = .short3
        case .short4:
            self = .short4
        case .ushort:
            self = .ushort
        case .ushort2:
            self = .ushort2
        case .ushort3:
            self = .ushort3
        case .ushort4:
            self = .ushort4
        case .char:
            self = .char
        case .char2:
            self = .char2
        case .char3:
            self = .char3
        case .char4:
            self = .char4
        case .uchar:
            self = .uchar
        case .uchar2:
            self = .uchar
        case .uchar3:
            self = .uchar3
        case .uchar4:
            self = .uchar4
        default:
            fatalError("Unsupported or unknown MTLDataType.")
        }
    }
}
