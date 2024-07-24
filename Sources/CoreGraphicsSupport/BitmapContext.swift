import BaseSupport
import CoreGraphics

public extension CGBitmapInfo {
    init(alphaInfo: CGImageAlphaInfo, byteOrderInfo: CGImageByteOrderInfo, formatInfo: CGImagePixelFormatInfo = .packed, useFloatComponents: Bool = false) {
        self.init(rawValue: alphaInfo.rawValue | byteOrderInfo.rawValue | (useFloatComponents ? CGBitmapInfo.floatComponents.rawValue : 0) | formatInfo.rawValue)
    }

    var alphaInfo: CGImageAlphaInfo {
        CGImageAlphaInfo(rawValue: rawValue & CGBitmapInfo.alphaInfoMask.rawValue).forceUnwrap("Could not extract alpha info.")
    }

    var byteOrderInfo: CGImageByteOrderInfo {
        CGImageByteOrderInfo(rawValue: rawValue & CGBitmapInfo.byteOrderMask.rawValue).forceUnwrap("Could not extract byte order info.")
    }

    var formatInfo: CGImagePixelFormatInfo {
        CGImagePixelFormatInfo(rawValue: rawValue & CGImagePixelFormatInfo.mask.rawValue).forceUnwrap("Could not extract format info.")
    }

    var useFloatComponents: Bool {
        CGImageAlphaInfo(rawValue: rawValue & CGBitmapInfo.floatInfoMask.rawValue).forceUnwrap("Could not extract use float components info.").rawValue != 0
    }
}

public extension CGContext {
    static func bitmapContext(data: UnsafeMutableRawBufferPointer? = nil, definition: BitmapDefinition) throws -> CGContext {
        // swiftlint:disable:next line_length

        var definition = definition
        if definition.pixelFormat.byteOrder == .orderDefault {
            // TODO: Other endianness?
            definition.pixelFormat.byteOrder = .order32Big
        }

        assert(data == nil || data?.count == definition.height * definition.bytesPerRow, "\(String(describing: data?.count)) == \(definition.height * definition.bytesPerRow)")

        guard let colorSpace = definition.pixelFormat.colorSpace else {
            throw BaseError.generic("No colorspace.")
        }

        guard let context = CGContext(data: data?.baseAddress, width: definition.width, height: definition.height, bitsPerComponent: definition.pixelFormat.bitsPerComponent, bytesPerRow: definition.bytesPerRow, space: colorSpace, bitmapInfo: definition.pixelFormat.bitmapInfo.rawValue) else {
            throw BaseError.generic("Could not create bitmap context")
        }
        return context
    }

    class func bitmapContext(bounds: CGRect, color: CGColor? = nil) -> CGContext {
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

public extension CGContext {
    static func bitmapContext(with image: CGImage) throws -> CGContext {
        guard let bitmapDefinition = BitmapDefinition(from: image) else {
            throw BaseError.generic("Could not create bitmap definition from image")
        }
        let context = try CGContext.bitmapContext(definition: bitmapDefinition)
        context.draw(image, in: CGRect(origin: .zero, size: image.size))
        return context
    }
}

public extension BitmapDefinition {
    init?(from image: CGImage) {
        guard let colorSpace = image.colorSpace else {
            return nil
        }
        let pixelFormat = PixelFormat(bitsPerComponent: image.bitsPerComponent, numberOfComponents: colorSpace.numberOfComponents, alphaInfo: image.alphaInfo, byteOrder: image.byteOrderInfo, colorSpace: colorSpace)
        self = .init(width: image.width, height: image.height, bytesPerRow: image.bytesPerRow, pixelFormat: pixelFormat)
    }
}
