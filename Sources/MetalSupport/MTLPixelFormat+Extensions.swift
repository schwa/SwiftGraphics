import BaseSupport
import CoreGraphics
import CoreGraphicsSupport
import Metal

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

    init?(from pixelFormat: PixelFormat) {
        let colorSpaceName = pixelFormat.colorSpace!.name! as String
        let bitmapInfo = CGBitmapInfo(rawValue: pixelFormat.bitmapInfo.rawValue & CGBitmapInfo.byteOrderMask.rawValue)
        switch (pixelFormat.numberOfComponents, pixelFormat.bitsPerComponent, pixelFormat.useFloatComponents, bitmapInfo, pixelFormat.alphaInfo, colorSpaceName) {
        case (3, 8, false, .byteOrder32Little, .premultipliedLast, "kCGColorSpaceDeviceRGB"):
            self = .bgra8Unorm
        default:
            return nil
        }
    }
}

public extension PixelFormat {
    // TODO: Test endianness. // TODO: This is clearly very broken and desparately needs offscreen rendering unit tests.
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
            self = .init(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order32Big, colorSpace: colorSpace)
        case .bgra8Unorm_srgb:
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
            self = .init(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order32Big, colorSpace: colorSpace)
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
