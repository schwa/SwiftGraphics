import CoreGraphics

public struct BitmapDefinition: Sendable {
    public var width: Int
    public var height: Int
    public var bytesPerRow: Int
    public var pixelFormat: PixelFormat

    public init(width: Int, height: Int, bytesPerRow: Int? = nil, pixelFormat: PixelFormat) {
        assert(width != 0 && height != 0, "BitmapDefinition must have non-zero width and height.")
        self.width = width
        self.height = height
        self.bytesPerRow = bytesPerRow ?? width * pixelFormat.bytesPerComponent * pixelFormat.numberOfComponents
        self.pixelFormat = pixelFormat
    }
}

public extension BitmapDefinition {
    var bounds: CGRect {
        CGRect(width: CGFloat(width), height: CGFloat(height))
    }
}

public struct PixelFormat: Sendable, Equatable {
    public var bitsPerComponent: Int
    public var numberOfComponents: Int
    public var alphaInfo: CGImageAlphaInfo
    public var byteOrder: CGImageByteOrderInfo
    public var formatInfo: CGImagePixelFormatInfo
    public var useFloatComponents: Bool
    public var colorSpace: CGColorSpace?

    public init(bitsPerComponent: Int, numberOfComponents: Int, alphaInfo: CGImageAlphaInfo, byteOrder: CGImageByteOrderInfo, formatInfo: CGImagePixelFormatInfo = .packed, useFloatComponents: Bool = false, colorSpace: CGColorSpace?) {
        self.bitsPerComponent = bitsPerComponent
        self.numberOfComponents = numberOfComponents
        self.alphaInfo = alphaInfo
        self.byteOrder = byteOrder
        self.formatInfo = formatInfo
        self.useFloatComponents = useFloatComponents
        self.colorSpace = colorSpace
    }

    var bytesPerComponent: Int {
        bitsPerComponent / 8
    }
}

public extension PixelFormat {
    var bitmapInfo: CGBitmapInfo {
        CGBitmapInfo(alphaInfo: alphaInfo, byteOrderInfo: byteOrder, formatInfo: formatInfo, useFloatComponents: useFloatComponents)
    }
}

/*
 |     16  bits per pixel,    |     5  bits per component
 kCGImageAlphaNoneSkipFirst |
 |     32  bits per pixel,    |     8  bits per component
 kCGImageAlphaNoneSkipFirst |
 |     32  bits per pixel,    |     8  bits per component
 kCGImageAlphaNoneSkipLast |
 |     32  bits per pixel,    |     8  bits per component
 kCGImageAlphaPremultipliedFirst |
 |     32  bits per pixel,    |     8  bits per component
 kCGImageAlphaPremultipliedLast |
 |     32  bits per pixel,    |     10 bits per component
 kCGImageAlphaNone|kCGImagePixelFormatRGBCIF10|kCGImageByteOrder16Little |
 |     64  bits per pixel,    |     16 bits per component
 kCGImageAlphaPremultipliedLast |
 |     64  bits per pixel,    |     16 bits per component
 kCGImageAlphaNoneSkipLast |
 |     64  bits per pixel,    |     16 bits per component
 kCGImageAlphaPremultipliedLast|kCGBitmapFloatComponents|kCGImageByteOrder16Little |
 |     64  bits per pixel,    |     16 bits per component
 kCGImageAlphaNoneSkipLast|kCGBitmapFloatComponents|kCGImageByteOrder16Little |
 |     128 bits per pixel,    |     32 bits per component
 kCGImageAlphaPremultipliedLast|kCGBitmapFloatComponents |
 |     128 bits per pixel,    |     32 bits per component
 kCGImageAlphaNoneSkipLast|kCGBitmapFloatComponents |
 */

public extension PixelFormat {
    static let rgba8 = PixelFormat(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .orderDefault, formatInfo: .packed, useFloatComponents: false, colorSpace: CGColorSpaceCreateDeviceRGB())
    static let rgba8srgb = PixelFormat(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .orderDefault, formatInfo: .packed, useFloatComponents: false, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
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
