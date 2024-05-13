import CoreGraphicsSupport
import Everything
import Foundation
import Metal
import MetalKit
import MetalPerformanceShaders
import MetalSupportUnsafeConformances
import ModelIO
import os
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

#if !os(visionOS)
    public extension MTKView {
        var betterDebugDescription: String {
            let attributes: [(String, String?)] = [
                ("delegate", delegate.map { String(describing: $0) }),
                ("device", device?.name),
                ("currentDrawable", currentDrawable.map { String(describing: $0) }),
                ("framebufferOnly", framebufferOnly.formatted()),
                ("depthStencilAttachmentTextureUsage", String(describing: depthStencilAttachmentTextureUsage)),
                ("multisampleColorAttachmentTextureUsage", String(describing: multisampleColorAttachmentTextureUsage)),
                ("presentsWithTransaction", presentsWithTransaction.formatted()),
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
                ("autoResizeDrawable", autoResizeDrawable.formatted()),
                ("drawableSize", String(describing: drawableSize)),
                ("preferredDrawableSize", String(describing: preferredDrawableSize)),
                ("preferredDevice", preferredDevice?.name),
                ("isPaused", isPaused.formatted()),
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

public extension MTLTexture {
    func cgImage(colorSpace: CGColorSpace? = nil) async -> CGImage {
        if let pixelFormat = PixelFormat(mtlPixelFormat: pixelFormat) {
            let bitmapDefinition = BitmapDefinition(width: width, height: height, pixelFormat: pixelFormat)
            if let buffer {
                let buffer = UnsafeMutableRawBufferPointer(start: buffer.contents(), count: buffer.length)
                guard let context = CGContext.bitmapContext(data: buffer, definition: bitmapDefinition) else {
                    fatalError()
                }
                return context.makeImage()!
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
                return data.withUnsafeMutableBytes { data in
                    guard let context = CGContext.bitmapContext(data: data, definition: bitmapDefinition) else {
                        fatalError()
                    }
                    return context.makeImage()!
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
            return await destinationTexture.cgImage()
        }
    }
}

extension MTLPixelFormat {
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

public extension PixelFormat {
    var bitsPerPixel: Int {
        switch formatInfo {
        case .packed:
            (bitsPerComponent * numberOfComponents)
        case .RGB555:
            // Only for RGB 16 bits per pixel, alpha != alpha none
            16
        case .RGB565:
            // Only for RGB 16 bits per pixel, alpha none
            16
        case .RGB101010:
            // Only for RGB 32 bits per pixel, alpha != none
            32
        case .RGBCIF10:
            // Only for RGB 32 bits per pixel,
            32
        default:
            fatalError("Unknown case")
        }
    }

    var bytesPerPixel: Int {
        bitsPerPixel / 8
    }
}

public extension MTLTexture {
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

// MARK: -

public extension MTLRenderCommandEncoder {
    func setVertexBuffer(_ mesh: MTKMesh, startingIndex: Int) {
        for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
            setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: startingIndex + index)
        }
    }

    func draw(_ mesh: MTKMesh) {
        for submesh in mesh.submeshes {
            drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        }
    }

    func draw(_ mesh: MTKMesh, instanceCount: Int) {
        for submesh in mesh.submeshes {
            drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset, instanceCount: instanceCount)
        }
    }
}

extension Transform {
    func scaled(_ scale: SIMD3<Float>) -> Transform {
        var copy = self
        copy.scale *= scale
        return copy
    }
}

public extension MTLDevice {
    func makeDebugLibrary(bundle: Bundle) throws -> MTLLibrary {
        if let url = bundle.url(forResource: "debug", withExtension: "metallib") {
            logger?.debug("Found debug metal library.")
            return try makeLibrary(URL: url)
        }
        else if let url = bundle.url(forResource: "default", withExtension: "metallib") {
            logger?.debug("Note: Found default metal library. Will be unable to debug metal.")
            return try makeLibrary(URL: url)
        }
        else {
            fatalError("Could not find metalib within shaders bundle \(bundle)")
        }
    }
}

extension MTLRenderCommandEncoder {
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

    public func withDebugGroup<R>(_ string: String, block: () throws -> R) rethrows -> R {
        pushDebugGroup(string)
        defer {
            popDebugGroup()
        }
        return try block()
    }
}
