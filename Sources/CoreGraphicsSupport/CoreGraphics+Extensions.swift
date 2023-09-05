import Accelerate
import CoreGraphics

#if os(macOS)
    import AppKit
#endif

#if os(macOS)
    public extension NSImage {
        convenience init(cgImage: CGImage) {
            self.init(cgImage: cgImage, size: CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
        }

        var cgImage: CGImage {
            guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                fatalError("Unimplemented")
            }
            return cgImage
        }
    }
#endif

public extension CGBitmapInfo {
    init(alphaInfo: CGImageAlphaInfo, byteOrderInfo: CGImageByteOrderInfo, formatInfo: CGImagePixelFormatInfo = .packed, useFloatComponents: Bool = false) {
        self.init(rawValue: alphaInfo.rawValue | byteOrderInfo.rawValue | (useFloatComponents ? CGBitmapInfo.floatComponents.rawValue : 0) | formatInfo.rawValue)
    }

    var alphaInfo: CGImageAlphaInfo {
        CGImageAlphaInfo(rawValue: rawValue & CGBitmapInfo.alphaInfoMask.rawValue)!
    }

    var byteOrderInfo: CGImageByteOrderInfo {
        CGImageByteOrderInfo(rawValue: rawValue & CGBitmapInfo.byteOrderMask.rawValue)!
    }

    var formatInfo: CGImagePixelFormatInfo {
        CGImagePixelFormatInfo(rawValue: rawValue & CGImagePixelFormatInfo.mask.rawValue)!
    }

    var useFloatComponents: Bool {
        CGImageAlphaInfo(rawValue: rawValue & CGBitmapInfo.floatInfoMask.rawValue)!.rawValue != 0
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

    public static let rgba = PixelFormat(bitsPerComponent: 8, numberOfComponents: 4, alphaInfo: .premultipliedLast, byteOrder: .order32Little, formatInfo: .packed, useFloatComponents: false, colorSpace: CGColorSpaceCreateDeviceRGB())
}

public extension PixelFormat {
    var bitmapInfo: CGBitmapInfo {
        CGBitmapInfo(alphaInfo: alphaInfo, byteOrderInfo: byteOrder, formatInfo: formatInfo, useFloatComponents: useFloatComponents)
    }
}

public struct BitmapDefinition {
    public let width: Int
    public let height: Int
    public let bitsPerComponent: Int
    public let bytesPerRow: Int
    public let colorSpace: CGColorSpace?
    public let bitmapInfo: CGBitmapInfo

    public init(width: Int, height: Int, bitsPerComponent: Int, bytesPerRow: Int, colorSpace: CGColorSpace?, bitmapInfo: CGBitmapInfo) {
        self.width = width
        self.height = height
        self.bitsPerComponent = bitsPerComponent
        self.bytesPerRow = bytesPerRow
        self.colorSpace = colorSpace
        self.bitmapInfo = bitmapInfo
    }
}

public extension BitmapDefinition {
    var bounds: CGRect {
        CGRect(width: CGFloat(width), height: CGFloat(height))
    }
}

public extension BitmapDefinition {
    init(width: Int, height: Int, pixelFormat: PixelFormat) {
        let bytesPerPixel = (pixelFormat.bitsPerComponent * pixelFormat.numberOfComponents) / 8
        self = BitmapDefinition(width: width, height: height, bitsPerComponent: pixelFormat.bitsPerComponent, bytesPerRow: width * bytesPerPixel, colorSpace: pixelFormat.colorSpace, bitmapInfo: pixelFormat.bitmapInfo)
    }
}

public extension CGContext {
    static func bitmapContext(data: UnsafeMutableRawBufferPointer? = nil, definition: BitmapDefinition) -> CGContext? {
        assert(data == nil || data!.count == definition.height * definition.bytesPerRow, "\(data!.count) == \(definition.height * definition.bytesPerRow)")
        // swiftlint:disable:next line_length
        return CGContext(data: data?.baseAddress, width: definition.width, height: definition.height, bitsPerComponent: definition.bitsPerComponent, bytesPerRow: definition.bytesPerRow, space: definition.colorSpace!, bitmapInfo: definition.bitmapInfo.rawValue)
    }

    class func bitmapContext(bounds: CGRect, color: CGColor? = nil) -> CGContext! {
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let width = Int(ceil(bounds.size.width))
        let height = Int(ceil(bounds.size.height))
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorspace, bitmapInfo: bitmapInfo.rawValue)!
        context.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)

        if let color {
            context.setFillColor(color)
            context.fill(bounds)
        }

        return context
    }
}

#if os(macOS)
    public extension CGContext {
        func makeImage(size: CGSize) -> NSImage {
            let image = makeImage()!
            return NSImage(cgImage: image, size: size)
        }
    }
#endif

public extension CGImage {
    func subimage(at frame: CGRect) -> CGImage {
        guard let context = CGContext.bitmapContext(bounds: CGRect(origin: .zero, size: frame.size)) else {
            fatalError("Could not make context.")
        }
        context.draw(self, in: CGRect(origin: -frame.origin, size: size))
        guard let image = context.makeImage() else {
            fatalError("Could not make image.")
        }
        return image
    }

    var size: CGSize {
        CGSize(width: width, height: height)
    }

    var frame: CGRect {
        CGRect(x: 0, y: 0, width: width, height: height)
    }
}
