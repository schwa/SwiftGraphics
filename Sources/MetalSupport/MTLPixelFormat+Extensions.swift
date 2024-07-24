import CoreGraphics
import CoreGraphicsSupport
import Metal

public extension MTLPixelFormat {
    // TODO: CGColorSpaceCreateLinearized?
    var colorSpace: CGColorSpace? {
        let deviceRGB = CGColorSpaceCreateDeviceRGB()
        let sRGB = CGColorSpace(name: CGColorSpace.sRGB)
        let extendedLinearSRGB = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
        switch self {
        case .r8Unorm_srgb:
            return sRGB
        case .rg8Unorm_srgb:
            return sRGB
        case .rgba8Unorm:
            return deviceRGB
        case .rgba8Unorm_srgb:
            return sRGB
        case .bgra8Unorm:
            return deviceRGB
        case .bgra8Unorm_srgb:
            return sRGB
        case .bgr10_xr:
            return deviceRGB
        case .bgr10_xr_srgb:
            return extendedLinearSRGB
        case .bgra10_xr:
            return deviceRGB
        case .bgra10_xr_srgb:
            return extendedLinearSRGB
        case .bc1_rgba_srgb:
            return sRGB
        case .bc2_rgba_srgb:
            return sRGB
        case .bc3_rgba_srgb:
            return sRGB
        case .bc7_rgbaUnorm_srgb:
            return sRGB
        case .pvrtc_rgb_2bpp_srgb:
            return sRGB
        case .pvrtc_rgb_4bpp_srgb:
            return sRGB
        case .pvrtc_rgba_2bpp_srgb:
            return sRGB
        case .pvrtc_rgba_4bpp_srgb:
            return sRGB
        case .eac_rgba8_srgb:
            return sRGB
        case .etc2_rgb8_srgb:
            return sRGB
        case .etc2_rgb8a1_srgb:
            return sRGB
        case .astc_4x4_srgb:
            return sRGB
        case .astc_5x4_srgb:
            return sRGB
        case .astc_5x5_srgb:
            return sRGB
        case .astc_6x5_srgb:
            return sRGB
        case .astc_6x6_srgb:
            return sRGB
        case .astc_8x5_srgb:
            return sRGB
        case .astc_8x6_srgb:
            return sRGB
        case .astc_8x8_srgb:
            return sRGB
        case .astc_10x5_srgb:
            return sRGB
        case .astc_10x6_srgb:
            return sRGB
        case .astc_10x8_srgb:
            return sRGB
        case .astc_10x10_srgb:
            return sRGB
        case .astc_12x10_srgb:
            return sRGB
        case .astc_12x12_srgb:
            return sRGB
        default:
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
        guard let colorSpaceName = pixelFormat.colorSpace?.name as? String else {
            fatalError("Unable to determine color space name for pixel format \(pixelFormat)")
        }
        let bitmapInfo = CGBitmapInfo(rawValue: pixelFormat.bitmapInfo.rawValue & CGBitmapInfo.byteOrderMask.rawValue)
        switch (pixelFormat.numberOfComponents, pixelFormat.bitsPerComponent, pixelFormat.useFloatComponents, bitmapInfo, pixelFormat.alphaInfo, colorSpaceName) {
        case (3, 8, false, .byteOrder32Little, .premultipliedLast, "kCGColorSpaceDeviceRGB"):
            self = .bgra8Unorm
        default:

            //            print(pixelFormat.numberOfComponents, pixelFormat.bitsPerComponent, pixelFormat.useFloatComponents, bitmapInfo, pixelFormat.alphaInfo, colorSpaceName)
            return nil
        }
    }
}

public extension PixelFormat {
    // TODO: FIXME FIXME FIXME FIXME FIXME FIXME FIXME

    // TODO: Test endianness. // TODO: This is clearly very broken and desparately needs offscreen rendering unit tests.
    // swiftlint:disable:next cyclomatic_complexity
    init?(_ pixelFormat: MTLPixelFormat) {
        guard let colorSpace = pixelFormat.colorSpace else {
            return nil
        }
        switch pixelFormat {
        case .rgba8Unorm:
            self = .init(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order32Big, colorSpace: colorSpace)
        case .bgra8Unorm:
            self = .init(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedFirst, byteOrder: .order32Little, colorSpace: colorSpace)
        case .bgra8Unorm_srgb:
            self = .init(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedFirst, byteOrder: .order32Little, colorSpace: colorSpace)
        default:
            return nil
        }
    }
}
