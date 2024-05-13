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

public enum RenderKitError: Error {
    case generic(String)
}

public protocol Labeled {
    var label: String? { get }
}

public extension PixelFormat {
    // TODO: Test endianness.
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

public func align(_ value: Int, alignment: Int) -> Int {
    (value + alignment - 1) / alignment * alignment
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

public extension MTLTexture {
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
        let image = context.makeImage()
        return image
    }
}

public extension MTLDevice {
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
}
