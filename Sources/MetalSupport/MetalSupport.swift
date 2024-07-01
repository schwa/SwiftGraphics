import CoreGraphics
import CoreGraphicsSupport
import Foundation
import Metal
import MetalKit
import MetalPerformanceShaders
import ModelIO
import os
import simd
import SIMDSupport
import SwiftUI

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length

// TODO: This file is a mess.

public enum MetalSupportError: Error {
    case illegalValue
    case resourceCreationFailure
    case missingBinding(String)
}

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
    func withRenderCommandEncoder<R>(descriptor: MTLRenderPassDescriptor, block: (MTLRenderCommandEncoder) throws -> R) rethrows -> R {
        guard let renderCommandEncoder = makeRenderCommandEncoder(descriptor: descriptor) else {
            fatalError("Failed to make render command encoder.")
        }
        defer {
            renderCommandEncoder.endEncoding()
        }
        return try block(renderCommandEncoder)
    }
}

public extension MTLCommandEncoder {
    func withDebugGroup<R>(_ string: String, _ closure: () throws -> R) rethrows -> R {
        pushDebugGroup(string)
        defer {
            popDebugGroup()
        }
        return try closure()
    }
}

public extension MTLCommandQueue {
    func withCommandBuffer<R>(waitAfterCommit wait: Bool, block: (MTLCommandBuffer) throws -> R) rethrows -> R {
        guard let commandBuffer = makeCommandBuffer() else {
            fatalError("Failed to make command buffer.")
        }
        defer {
            commandBuffer.commit()
            if wait {
                commandBuffer.waitUntilCompleted()
            }
        }
        return try block(commandBuffer)
    }

    func withCommandBuffer<R>(drawable: @autoclosure () -> (any MTLDrawable)?, block: (MTLCommandBuffer) throws -> R) rethrows -> R {
        guard let commandBuffer = makeCommandBuffer() else {
            fatalError("Failed to make command buffer.")
        }
        defer {
            if let drawable = drawable() {
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

    func makeBuffer(length: Int, options: MTLResourceOptions = []) throws -> MTLBuffer {
        guard let buffer = makeBuffer(length: length, options: options) else {
            throw MetalSupportError.resourceCreationFailure
        }
        return buffer
    }

    func makeBuffer(data: Data, options: MTLResourceOptions) throws -> MTLBuffer {
        try data.withUnsafeBytes { buffer in
            guard let buffer = makeBuffer(bytes: buffer.baseAddress!, length: buffer.count, options: options) else {
                throw MetalSupportError.resourceCreationFailure
            }
            return buffer
        }
    }

    func makeBuffer(bytesOf content: some Any, options: MTLResourceOptions) throws -> MTLBuffer {
        try withUnsafeBytes(of: content) { buffer in
            guard let buffer = makeBuffer(bytes: buffer.baseAddress!, length: buffer.count, options: options) else {
                throw MetalSupportError.resourceCreationFailure
            }
            return buffer
        }
    }

    func makeBuffer(bytesOf content: [some Any], options: MTLResourceOptions) throws -> MTLBuffer {
        try content.withUnsafeBytes { buffer in
            guard let buffer = makeBuffer(bytes: buffer.baseAddress!, length: buffer.count, options: options) else {
                throw MetalSupportError.resourceCreationFailure
            }
            return buffer
        }
    }

    var supportsNonuniformThreadGroupSizes: Bool {
        let families: [MTLGPUFamily] = [.apple4, .apple5, .apple6, .apple7]
        return families.contains { supportsFamily($0) }
    }

    func newTexture(with image: CGImage) throws -> MTLTexture {
        guard let bitmapDefinition = BitmapDefinition(from: image) else {
            fatalError()
        }
        guard let context = CGContext.bitmapContext(with: image), let data = context.data else {
            fatalError()
        }
        guard let pixelFormat = MTLPixelFormat(from: bitmapDefinition.pixelFormat) else {
            fatalError()
        }
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: image.width, height: image.height, mipmapped: true)
        guard let texture = makeTexture(descriptor: textureDescriptor) else {
            fatalError()
        }
        texture.replace(region: MTLRegion(origin: .zero, size: MTLSize(image.width, image.height, 1)), mipmapLevel: 0, slice: 0, withBytes: data, bytesPerRow: bitmapDefinition.bytesPerRow, bytesPerImage: bitmapDefinition.bytesPerRow * image.height)
        return texture
    }

    func makeDebugLibrary(bundle: Bundle) throws -> MTLLibrary {
        if let url = bundle.url(forResource: "debug", withExtension: "metallib") {
            return try makeLibrary(URL: url)
        }
        else {
            Logger().warning("Failed to load debug metal library, falling back to bundle's default library.")
            return try makeDefaultLibrary(bundle: bundle)
        }
    }
}

public extension MTLFunctionConstantValues {
    convenience init(dictionary: [Int: Any]) {
        self.init()

        for (index, value) in dictionary {
            withUnsafeBytes(of: value) { buffer in
                setConstantValue(buffer.baseAddress!, type: .bool, index: index)
            }
        }
    }

    func setConstantValue(_ value: Bool, index: Int) {
        withUnsafeBytes(of: value) { buffer in
            setConstantValue(buffer.baseAddress!, type: .bool, index: 0)
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
            fatalError(MetalSupportError.illegalValue)
        }
    }
}

public extension MTLOrigin {
    init(_ origin: CGPoint) {
        self.init(x: Int(origin.x), y: Int(origin.y), z: 0)
    }

    static var zero: MTLOrigin {
        MTLOrigin(x: 0, y: 0, z: 0)
    }
}

public extension MTLPixelFormat {
    var colorSpace: CGColorSpace? {
        switch self {
        case .invalid:
            return nil
        case .a8Unorm:
            return nil
        case .r8Unorm:
            return nil
        case .r8Unorm_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .r8Snorm:
            return nil
        case .r8Uint:
            return nil
        case .r8Sint:
            return nil
        case .r16Unorm:
            return nil
        case .r16Snorm:
            return nil
        case .r16Uint:
            return nil
        case .r16Sint:
            return nil
        case .r16Float:
            return nil
        case .rg8Unorm:
            return nil
        case .rg8Unorm_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .rg8Snorm:
            return nil
        case .rg8Uint:
            return nil
        case .rg8Sint:
            return nil
        case .b5g6r5Unorm:
            return nil
        case .a1bgr5Unorm:
            return nil
        case .abgr4Unorm:
            return nil
        case .bgr5A1Unorm:
            return nil
        case .r32Uint:
            return nil
        case .r32Sint:
            return nil
        case .r32Float:
            return nil
        case .rg16Unorm:
            return nil
        case .rg16Snorm:
            return nil
        case .rg16Uint:
            return nil
        case .rg16Sint:
            return nil
        case .rg16Float:
            return nil
        case .rgba8Unorm:
            return nil
        case .rgba8Unorm_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .rgba8Snorm:
            return nil
        case .rgba8Uint:
            return nil
        case .rgba8Sint:
            return nil
        case .bgra8Unorm:
            return nil
        case .bgra8Unorm_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .rgb10a2Unorm:
            return nil
        case .rgb10a2Uint:
            return nil
        case .rg11b10Float:
            return nil
        case .rgb9e5Float:
            return nil
        case .bgr10a2Unorm:
            return nil
        case .bgr10_xr:
            return CGColorSpaceCreateDeviceRGB()
        case .bgr10_xr_srgb:
            return CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
        case .rg32Uint:
            return nil
        case .rg32Sint:
            return nil
        case .rg32Float:
            return nil
        case .rgba16Unorm:
            return nil
        case .rgba16Snorm:
            return nil
        case .rgba16Uint:
            return nil
        case .rgba16Sint:
            return nil
        case .rgba16Float:
            return nil
        case .bgra10_xr:
            return CGColorSpaceCreateDeviceRGB()
        case .bgra10_xr_srgb:
            return CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
        case .rgba32Uint:
            return nil
        case .rgba32Sint:
            return nil
        case .rgba32Float:
            return nil
        case .bc1_rgba:
            return nil
        case .bc1_rgba_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .bc2_rgba:
            return nil
        case .bc2_rgba_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .bc3_rgba:
            return nil
        case .bc3_rgba_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .bc4_rUnorm:
            return nil
        case .bc4_rSnorm:
            return nil
        case .bc5_rgUnorm:
            return nil
        case .bc5_rgSnorm:
            return nil
        case .bc6H_rgbFloat:
            return nil
        case .bc6H_rgbuFloat:
            return nil
        case .bc7_rgbaUnorm:
            return nil
        case .bc7_rgbaUnorm_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .pvrtc_rgb_2bpp:
            return nil
        case .pvrtc_rgb_2bpp_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .pvrtc_rgb_4bpp:
            return nil
        case .pvrtc_rgb_4bpp_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .pvrtc_rgba_2bpp:
            return nil
        case .pvrtc_rgba_2bpp_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .pvrtc_rgba_4bpp:
            return nil
        case .pvrtc_rgba_4bpp_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .eac_r11Unorm:
            return nil
        case .eac_r11Snorm:
            return nil
        case .eac_rg11Unorm:
            return nil
        case .eac_rg11Snorm:
            return nil
        case .eac_rgba8:
            return nil
        case .eac_rgba8_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .etc2_rgb8:
            return nil
        case .etc2_rgb8_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .etc2_rgb8a1:
            return nil
        case .etc2_rgb8a1_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_4x4_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_5x4_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_5x5_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_6x5_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_6x6_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_8x5_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_8x6_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_8x8_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_10x5_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_10x6_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_10x8_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_10x10_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_12x10_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_12x12_srgb:
            return CGColorSpace(name: CGColorSpace.sRGB)
        case .astc_4x4_ldr:
            return nil
        case .astc_5x4_ldr:
            return nil
        case .astc_5x5_ldr:
            return nil
        case .astc_6x5_ldr:
            return nil
        case .astc_6x6_ldr:
            return nil
        case .astc_8x5_ldr:
            return nil
        case .astc_8x6_ldr:
            return nil
        case .astc_8x8_ldr:
            return nil
        case .astc_10x5_ldr:
            return nil
        case .astc_10x6_ldr:
            return nil
        case .astc_10x8_ldr:
            return nil
        case .astc_10x10_ldr:
            return nil
        case .astc_12x10_ldr:
            return nil
        case .astc_12x12_ldr:
            return nil
        case .astc_4x4_hdr:
            return nil
        case .astc_5x4_hdr:
            return nil
        case .astc_5x5_hdr:
            return nil
        case .astc_6x5_hdr:
            return nil
        case .astc_6x6_hdr:
            return nil
        case .astc_8x5_hdr:
            return nil
        case .astc_8x6_hdr:
            return nil
        case .astc_8x8_hdr:
            return nil
        case .astc_10x5_hdr:
            return nil
        case .astc_10x6_hdr:
            return nil
        case .astc_10x8_hdr:
            return nil
        case .astc_10x10_hdr:
            return nil
        case .astc_12x10_hdr:
            return nil
        case .astc_12x12_hdr:
            return nil
        case .gbgr422:
            return nil
        case .bgrg422:
            return nil
        case .depth16Unorm:
            return nil
        case .depth32Float:
            return nil
        case .stencil8:
            return nil
        case .depth24Unorm_stencil8:
            return nil
        case .depth32Float_stencil8:
            return nil
        case .x32_stencil8:
            return nil
        case .x24_stencil8:
            return nil
        @unknown default:
            return nil
        }
    }

    var bits: Int? {
        switch self {
        /* Normal 8 bit formats */
        case .a8Unorm, .r8Unorm, .r8Unorm_srgb, .r8Snorm, .r8Uint, .r8Sint:
            8
        /* Normal 16 bit formats */
        case .r16Unorm, .r16Snorm, .r16Uint, .r16Sint, .r16Float, .rg8Unorm, .rg8Unorm_srgb, .rg8Snorm, .rg8Uint, .rg8Sint:
            16
        /* Packed 16 bit formats */
        case .b5g6r5Unorm, .a1bgr5Unorm, .abgr4Unorm, .bgr5A1Unorm:
            16
        /* Normal 32 bit formats */
        case .r32Uint, .r32Sint, .r32Float, .rg16Unorm, .rg16Snorm, .rg16Uint, .rg16Sint, .rg16Float, .rgba8Unorm, .rgba8Unorm_srgb, .rgba8Snorm, .rgba8Uint, .rgba8Sint, .bgra8Unorm, .bgra8Unorm_srgb:
            32
        /* Packed 32 bit formats */
        case .rgb10a2Unorm, .rgb10a2Uint, .rg11b10Float, .rgb9e5Float, .bgr10a2Unorm, .bgr10_xr, .bgr10_xr_srgb:
            32
        /* Normal 64 bit formats */
        case .rg32Uint, .rg32Sint, .rg32Float, .rgba16Unorm, .rgba16Snorm, .rgba16Uint, .rgba16Sint, .rgba16Float, .bgra10_xr, .bgra10_xr_srgb:
            64
        /* Normal 128 bit formats */
        case .rgba32Uint, .rgba32Sint, .rgba32Float:
            128
        /* Depth */
        case .depth16Unorm:
            16
        case .depth32Float:
            32
        /* Stencil */
        case .stencil8:
            8
        /* Depth Stencil */
        case .depth24Unorm_stencil8:
            32
        case .depth32Float_stencil8:
            40
        case .x32_stencil8:
            nil
        case .x24_stencil8:
            nil
        default:
            nil
        }
    }

    var size: Int? {
        bits.map { $0 / 8 }
    }
}

public extension MTLPrimitiveType {
    var vertexCount: Int? {
        switch self {
        case .triangle:
            3
        default:
            fatalError(MetalSupportError.illegalValue)
        }
    }
}

public extension MTLRegion {
    init(_ rect: CGRect) {
        self = MTLRegion(origin: MTLOrigin(rect.origin), size: MTLSize(rect.size))
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

    @available(*, deprecated, message: "Deprecated. Clean this up.")
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

    @available(*, deprecated, message: "Deprecated. Clean this up.")
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

    @available(*, deprecated, message: "Deprecated. Clean this up.")
    func draw(_ mesh: MTKMesh, instanceCount: Int) {
        for submesh in mesh.submeshes {
            drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset, instanceCount: instanceCount)
        }
    }

    @available(*, deprecated, message: "Deprecated. Clean this up.")
    func setVertexBuffer(_ mesh: MTKMesh, startingIndex: Int) {
        for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
            setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: startingIndex + index)
        }
    }
}

public extension MTLSize {
    init(_ size: CGSize) {
        self.init(width: Int(size.width), height: Int(size.height), depth: 1)
    }

    init(_ width: Int, _ height: Int, _ depth: Int) {
        self = MTLSize(width: width, height: height, depth: depth)
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
            replace(region: region, mipmapLevel: 0, withBytes: pointer.baseAddress!, bytesPerRow: width * MemoryLayout<SIMD4<UInt8>>.stride)
        }
    }

//    @available(*, deprecated, message: "Deprecate if can't be provide working in unit tests.")
    // TODO: Maybe deprecate?
    func cgImage() -> CGImage? {
        guard let pixelFormat = PixelFormat(pixelFormat) else {
            return nil
        }
        guard let context = CGContext.bitmapContext(definition: .init(width: width, height: height, pixelFormat: pixelFormat)) else {
            return nil
        }
        guard let pixelBytes = context.data else {
            return nil
        }
        getBytes(pixelBytes, bytesPerRow: context.bytesPerRow, from: MTLRegion(origin: .zero, size: MTLSize(width, height, 1)), mipmapLevel: 0)
        return context.makeImage()
    }

    @available(*, deprecated, message: "Deprecate if can't be provide working in unit tests.")
    func cgImage(colorSpace: CGColorSpace? = nil) async throws -> CGImage {
        if let pixelFormat = PixelFormat(mtlPixelFormat: pixelFormat) {
            let bitmapDefinition = BitmapDefinition(width: width, height: height, pixelFormat: pixelFormat)
            if let buffer {
                let buffer = UnsafeMutableRawBufferPointer(start: buffer.contents(), count: buffer.length)
                guard let context = CGContext.bitmapContext(data: buffer, definition: bitmapDefinition) else {
                    fatalError()
                }
                guard let image = context.makeImage() else {
                    throw MetalSupportError.resourceCreationFailure
                }
                return image
            }
            else {
                let bytesPerRow = bufferBytesPerRow != 0 ? bufferBytesPerRow : width * pixelFormat.bytesPerPixel
                var data = Data(count: bytesPerRow * height)
                data.withUnsafeMutableBytes { buffer in
                    guard let baseAddress = buffer.baseAddress else {
                        fatalError()
                    }
                    let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: width, height: height, depth: 1))
                    return getBytes(baseAddress, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
                }
                return try data.withUnsafeMutableBytes { data in
                    guard let context = CGContext.bitmapContext(data: data, definition: bitmapDefinition) else {
                        fatalError()
                    }
                    guard let image = context.makeImage() else {
                        throw MetalSupportError.resourceCreationFailure
                    }
                    return image
                }
            }
        }
//            // https://developer.apple.com/documentation/metal/mtltexture/1515598-newtextureviewwithpixelformat
        else {
            guard let srcColorSpace = pixelFormat.colorSpace else {
                fatalError("No colorspace for \(pixelFormat)")
            }
            guard let dstColorSpace = colorSpace else {
                fatalError()
            }
            let destinationTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: width, height: height, mipmapped: false)
            destinationTextureDescriptor.usage = [.shaderRead, .shaderWrite]
            guard let destinationTexture = device.makeTexture(descriptor: destinationTextureDescriptor) else {
                fatalError()
            }
            let conversionInfo = CGColorConversionInfo(src: srcColorSpace, dst: dstColorSpace)
            // TODO: we're just assuming premultiplied here.
            let conversion = MPSImageConversion(device: device, srcAlpha: .premultiplied, destAlpha: .premultiplied, backgroundColor: nil, conversionInfo: conversionInfo)
            let commandQueue = device.makeCommandQueue()!
            let commandBuffer = commandQueue.makeCommandBuffer()!
            conversion.encode(commandBuffer: commandBuffer, sourceTexture: self, destinationTexture: destinationTexture)
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            return try await destinationTexture.cgImage()
        }
    }

    func histogram() -> MTLBuffer {
        let filter = MPSImageHistogram(device: device)
        let size = filter.histogramSize(forSourceFormat: pixelFormat)
        guard let histogram = device.makeBuffer(length: size) else {
            fatalError()
        }
        let commandQueue = device.makeCommandQueue()!
        let commandBuffer = commandQueue.makeCommandBuffer()!
        filter.encode(to: commandBuffer, sourceTexture: self, histogram: histogram, histogramOffset: 0)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        return histogram
    }
}

// TODO: Move
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
}

public extension MTLTextureDescriptor {
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

public extension PixelFormat {
    init?(mtlPixelFormat: MTLPixelFormat) {
//    CGBitmapContextCreate:
//        Valid parameters for RGB color space model are:
//        16  bits per pixel,         5  bits per component,         kCGImageAlphaNoneSkipFirst
//        32  bits per pixel,         8  bits per component,         kCGImageAlphaNoneSkipFirst
//        32  bits per pixel,         8  bits per component,         kCGImageAlphaNoneSkipLast
//        32  bits per pixel,         8  bits per component,         kCGImageAlphaPremultipliedFirst
//        32  bits per pixel,         8  bits per component,         kCGImageAlphaPremultipliedLast
//        32  bits per pixel,         10 bits per component,         kCGImageAlphaNone|kCGImagePixelFormatRGBCIF10|kCGImageByteOrder16Little
//        64  bits per pixel,         16 bits per component,         kCGImageAlphaPremultipliedLast
//        64  bits per pixel,         16 bits per component,         kCGImageAlphaNoneSkipLast
//        64  bits per pixel,         16 bits per component,         kCGImageAlphaPremultipliedLast|kCGBitmapFloatComponents|k

        switch mtlPixelFormat {
        case .bgra8Unorm:
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            self = .init(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedFirst, byteOrder: .order32Little, colorSpace: colorSpace)
        case .bgra8Unorm_srgb:
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
            self = .init(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedFirst, byteOrder: .order32Little, colorSpace: colorSpace)
        case .rgba8Unorm:
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            self = .init(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order32Big, colorSpace: colorSpace)
        case .rgba8Unorm_srgb:
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
            self = .init(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order32Big, colorSpace: colorSpace)
        case .rgba32Float:
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            self = .init(bitsPerComponent: 32, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order32Little, useFloatComponents: true, colorSpace: colorSpace)
        case .bgra10_xr:
//            let colorSpace = CGColorSpaceCreateDeviceRGB()
//            self = .init(bitsPerComponent: 10, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order16Little, formatInfo: .RGB101010, colorSpace: colorSpace)
            return nil

        default:
            return nil
        }
    }
}

public extension Transform {
    func scaled(_ scale: SIMD3<Float>) -> Transform {
        var copy = self
        copy.scale *= scale
        return copy
    }
}

internal func fatalError(_ error: Error) -> Never {
    fatalError("\(error)")
}

#if !os(visionOS)
    public extension MTKView {
        var betterDebugDescription: String {
            let attributes: [(String, String?)] = [
                ("delegate", delegate.map { String(describing: $0) }),
                ("device", device?.name),
                ("currentDrawable", currentDrawable.map { String(describing: $0) }),
                ("framebufferOnly", String(describing: framebufferOnly)),
                ("depthStencilAttachmentTextureUsage", String(describing: depthStencilAttachmentTextureUsage)),
                ("multisampleColorAttachmentTextureUsage", String(describing: multisampleColorAttachmentTextureUsage)),
                ("presentsWithTransaction", String(describing: presentsWithTransaction)),
                ("colorPixelFormat", String(describing: colorPixelFormat)),
                ("depthStencilPixelFormat", String(describing: depthStencilPixelFormat)),
                ("depthStencilStorageMode", String(describing: depthStencilStorageMode)),
                ("sampleCount", sampleCount.formatted()),
                ("clearColor", String(describing: clearColor)),
                ("clearDepth", clearDepth.formatted()),
                ("clearStencil", clearStencil.formatted()),
                //            ("depthStencilTexture", String(describing: depthStencilTexture)),
                ("multisampleColorTexture", String(describing: multisampleColorTexture)),
                ("currentRenderPassDescriptor", String(describing: currentRenderPassDescriptor)),
                ("preferredFramesPerSecond", String(describing: preferredFramesPerSecond)),
                ("enableSetNeedsDisplay", String(describing: enableSetNeedsDisplay)),
                ("autoResizeDrawable", String(describing: autoResizeDrawable)),
                ("drawableSize", String(describing: drawableSize)),
                ("preferredDrawableSize", String(describing: preferredDrawableSize)),
                ("preferredDevice", preferredDevice?.name),
                ("isPaused", String(describing: isPaused)),
//            ("colorspace", String(describing: colorspace)),
            ]
            let formattedAttributes = attributes.compactMap { key, value in
                value.map { value in "\t\(key): \(value)" }
            }
            .joined(separator: ",\n")
            return "\(self) (\n\(formattedAttributes)\n)"
        }
    }
#endif

public extension SIMD4<Double> {
    init(_ clearColor: MTLClearColor) {
        self = [clearColor.red, clearColor.green, clearColor.blue, clearColor.alpha]
    }
}

public extension PixelFormat {
    // TODO: Test endianness.
    // swiftlint:disable:next cyclomatic_complexity
    init?(_ pixelFormat: MTLPixelFormat) {
        switch pixelFormat {
        case .invalid:
            return nil
        case .a8Unorm:
            let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)
            self = .init(bitsPerComponent: 8, numberOfComponents: 1, alphaInfo: .alphaOnly, byteOrder: .orderDefault, colorSpace: colorSpace)
        case .r8Unorm:
            let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)
            self = .init(bitsPerComponent: 8, numberOfComponents: 1, alphaInfo: .none, byteOrder: .orderDefault, colorSpace: colorSpace)
        case .r8Unorm_srgb:
            let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)
            self = .init(bitsPerComponent: 8, numberOfComponents: 1, alphaInfo: .none, byteOrder: .orderDefault, colorSpace: colorSpace)
        case .r8Snorm:
            return nil
        case .r8Uint:
            let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)
            self = .init(bitsPerComponent: 8, numberOfComponents: 1, alphaInfo: .none, byteOrder: .orderDefault, colorSpace: colorSpace)
        case .r8Sint:
            return nil
        case .r16Unorm:
            let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)
            self = .init(bitsPerComponent: 16, numberOfComponents: 1, alphaInfo: .none, byteOrder: .orderDefault, colorSpace: colorSpace)
        case .r16Snorm:
            return nil
        case .r16Uint:
            let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)
            self = .init(bitsPerComponent: 16, numberOfComponents: 1, alphaInfo: .none, byteOrder: .orderDefault, colorSpace: colorSpace)
        case .r16Sint:
            return nil
        case .r16Float:
            let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)
            self = .init(bitsPerComponent: 16, numberOfComponents: 1, alphaInfo: .none, byteOrder: .order16Little, useFloatComponents: true, colorSpace: colorSpace)
        case .rg8Unorm:
            return nil
        case .rg8Unorm_srgb:
            return nil
        case .rg8Snorm:
            return nil
        case .rg8Uint:
            return nil
        case .rg8Sint:
            return nil
        case .b5g6r5Unorm:
            return nil
        case .a1bgr5Unorm:
            return nil
        case .abgr4Unorm:
            return nil
        case .bgr5A1Unorm:
            return nil
        case .r32Uint:
            return nil
        case .r32Sint:
            return nil
        case .r32Float:
            let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)
            self = .init(bitsPerComponent: 32, numberOfComponents: 1, alphaInfo: .none, byteOrder: .orderDefault, useFloatComponents: true, colorSpace: colorSpace)
        case .rg16Unorm:
            return nil
        case .rg16Snorm:
            return nil
        case .rg16Uint:
            return nil
        case .rg16Sint:
            return nil
        case .rg16Float:
            return nil
        case .rgba8Unorm:
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
            self = .init(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order32Big, colorSpace: colorSpace)
        case .rgba8Unorm_srgb:
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
            self = .init(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order32Big, colorSpace: colorSpace)
        case .rgba8Snorm:
            return nil
        case .rgba8Uint:
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
            self = .init(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order32Big, colorSpace: colorSpace)
        case .rgba8Sint:
            return nil
        case .bgra8Unorm:
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
            self = .init(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order32Little, colorSpace: colorSpace)
        case .bgra8Unorm_srgb:
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
            self = .init(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order32Little, colorSpace: colorSpace)
        case .rgb10a2Unorm:
            return nil
        case .rgb10a2Uint:
            return nil
        case .rg11b10Float:
            return nil
        case .rgb9e5Float:
            return nil
        case .bgr10a2Unorm:
            return nil
        case .bgr10_xr:
            return nil
        case .bgr10_xr_srgb:
            return nil
        case .rg32Uint:
            return nil
        case .rg32Sint:
            return nil
        case .rg32Float:
            return nil
        case .rgba16Unorm:
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
            self = .init(bitsPerComponent: 16, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .orderDefault, colorSpace: colorSpace)
        case .rgba16Snorm:
            return nil
        case .rgba16Uint:
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
            self = .init(bitsPerComponent: 16, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .orderDefault, colorSpace: colorSpace)
        case .rgba16Sint:
            return nil
        case .rgba16Float:
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
            self = .init(bitsPerComponent: 16, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order16Little, useFloatComponents: true, colorSpace: colorSpace)
        case .bgra10_xr:
            return nil
        case .bgra10_xr_srgb:
            return nil
        case .rgba32Uint:
            return nil
        case .rgba32Sint:
            return nil
        case .rgba32Float:
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
            self = .init(bitsPerComponent: 32, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order32Big, useFloatComponents: true, colorSpace: colorSpace)
        case .bc1_rgba:
            return nil
        case .bc1_rgba_srgb:
            return nil
        case .bc2_rgba:
            return nil
        case .bc2_rgba_srgb:
            return nil
        case .bc3_rgba:
            return nil
        case .bc3_rgba_srgb:
            return nil
        case .bc4_rUnorm:
            return nil
        case .bc4_rSnorm:
            return nil
        case .bc5_rgUnorm:
            return nil
        case .bc5_rgSnorm:
            return nil
        case .bc6H_rgbFloat:
            return nil
        case .bc6H_rgbuFloat:
            return nil
        case .bc7_rgbaUnorm:
            return nil
        case .bc7_rgbaUnorm_srgb:
            return nil
        case .pvrtc_rgb_2bpp:
            return nil
        case .pvrtc_rgb_2bpp_srgb:
            return nil
        case .pvrtc_rgb_4bpp:
            return nil
        case .pvrtc_rgb_4bpp_srgb:
            return nil
        case .pvrtc_rgba_2bpp:
            return nil
        case .pvrtc_rgba_2bpp_srgb:
            return nil
        case .pvrtc_rgba_4bpp:
            return nil
        case .pvrtc_rgba_4bpp_srgb:
            return nil
        case .eac_r11Unorm:
            return nil
        case .eac_r11Snorm:
            return nil
        case .eac_rg11Unorm:
            return nil
        case .eac_rg11Snorm:
            return nil
        case .eac_rgba8:
            return nil
        case .eac_rgba8_srgb:
            return nil
        case .etc2_rgb8:
            return nil
        case .etc2_rgb8_srgb:
            return nil
        case .etc2_rgb8a1:
            return nil
        case .etc2_rgb8a1_srgb:
            return nil
        case .astc_4x4_srgb:
            return nil
        case .astc_5x4_srgb:
            return nil
        case .astc_5x5_srgb:
            return nil
        case .astc_6x5_srgb:
            return nil
        case .astc_6x6_srgb:
            return nil
        case .astc_8x5_srgb:
            return nil
        case .astc_8x6_srgb:
            return nil
        case .astc_8x8_srgb:
            return nil
        case .astc_10x5_srgb:
            return nil
        case .astc_10x6_srgb:
            return nil
        case .astc_10x8_srgb:
            return nil
        case .astc_10x10_srgb:
            return nil
        case .astc_12x10_srgb:
            return nil
        case .astc_12x12_srgb:
            return nil
        case .astc_4x4_ldr:
            return nil
        case .astc_5x4_ldr:
            return nil
        case .astc_5x5_ldr:
            return nil
        case .astc_6x5_ldr:
            return nil
        case .astc_6x6_ldr:
            return nil
        case .astc_8x5_ldr:
            return nil
        case .astc_8x6_ldr:
            return nil
        case .astc_8x8_ldr:
            return nil
        case .astc_10x5_ldr:
            return nil
        case .astc_10x6_ldr:
            return nil
        case .astc_10x8_ldr:
            return nil
        case .astc_10x10_ldr:
            return nil
        case .astc_12x10_ldr:
            return nil
        case .astc_12x12_ldr:
            return nil
        case .astc_4x4_hdr:
            return nil
        case .astc_5x4_hdr:
            return nil
        case .astc_5x5_hdr:
            return nil
        case .astc_6x5_hdr:
            return nil
        case .astc_6x6_hdr:
            return nil
        case .astc_8x5_hdr:
            return nil
        case .astc_8x6_hdr:
            return nil
        case .astc_8x8_hdr:
            return nil
        case .astc_10x5_hdr:
            return nil
        case .astc_10x6_hdr:
            return nil
        case .astc_10x8_hdr:
            return nil
        case .astc_10x10_hdr:
            return nil
        case .astc_12x10_hdr:
            return nil
        case .astc_12x12_hdr:
            return nil
        case .gbgr422:
            return nil
        case .bgrg422:
            return nil
        case .depth16Unorm:
            return nil
        case .depth32Float:
            return nil
        case .stencil8:
            return nil
        case .depth24Unorm_stencil8:
            return nil
        case .depth32Float_stencil8:
            return nil
        case .x32_stencil8:
            return nil
        case .x24_stencil8:
            return nil
        @unknown default:
            return nil
        }
    }
}

public extension MTLPixelFormat {
    init?(from pixelFormat: PixelFormat) {
        let colorSpaceName = pixelFormat.colorSpace!.name! as String
        let bitmapInfo = CGBitmapInfo(rawValue: pixelFormat.bitmapInfo.rawValue & CGBitmapInfo.byteOrderMask.rawValue)
        switch (pixelFormat.numberOfComponents, pixelFormat.bitsPerComponent, pixelFormat.useFloatComponents, bitmapInfo, pixelFormat.alphaInfo, colorSpaceName) {
        case (3, 8, false, .byteOrder32Little, .premultipliedLast, "kCGColorSpaceDeviceRGB"):
            self = .bgra8Unorm
        default:
            print("NO MATCH")
            return nil
        }
    }
}
