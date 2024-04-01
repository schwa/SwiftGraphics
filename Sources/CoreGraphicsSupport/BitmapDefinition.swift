import CoreGraphics

public struct BitmapDefinition {
    public var width: Int
    public var height: Int
    public var bytesPerRow: Int
    public var pixelFormat: PixelFormat

    public init(width: Int, height: Int, bytesPerRow: Int? = 0, pixelFormat: PixelFormat) {
        self.width = width
        self.height = height
        self.bytesPerRow = bytesPerRow ?? width * pixelFormat.bytesPerComponent
        self.pixelFormat = pixelFormat
    }
}

public extension BitmapDefinition {
    var bounds: CGRect {
        CGRect(width: CGFloat(width), height: CGFloat(height))
    }
}

public struct PixelFormat {
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

public extension PixelFormat {
    static let rgba8 = PixelFormat(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order32Little, formatInfo: .packed, useFloatComponents: false, colorSpace: CGColorSpaceCreateDeviceRGB())
}
