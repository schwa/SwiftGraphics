import CoreGraphics

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

public extension CGContext {
    static func bitmapContext(data: UnsafeMutableRawBufferPointer? = nil, definition: BitmapDefinition) -> CGContext? {
        assert(data == nil || data!.count == definition.height * definition.bytesPerRow, "\(data!.count) == \(definition.height * definition.bytesPerRow)")
        // swiftlint:disable:next line_length
        return CGContext(data: data?.baseAddress, width: definition.width, height: definition.height, bitsPerComponent: definition.pixelFormat.bitsPerComponent, bytesPerRow: definition.bytesPerRow, space: definition.pixelFormat.colorSpace!, bitmapInfo: definition.pixelFormat.bitmapInfo.rawValue)
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
