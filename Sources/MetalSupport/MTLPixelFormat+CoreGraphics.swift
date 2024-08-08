import BaseSupport
import CoreGraphics
import CoreGraphicsSupport
import Metal

public extension MTLPixelFormat {
    // IDEA: Use CGColorSpaceCreateLinearized?
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

    init?(from pixelFormat: PixelFormat) {
        guard let colorSpaceName = pixelFormat.colorSpace?.name as? String else {
            fatalError(BaseError.invalidParameter)
        }
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
