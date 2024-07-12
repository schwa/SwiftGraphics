import BaseSupport
import CoreGraphics

public extension CGColor {
    func makeImage(colorSpace: CGColorSpace? = nil) throws -> CGImage {
        guard let colorSpace = colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) else {
            fatalError("Could not create color space")
        }
        guard let converted = converted(to: colorSpace, intent: .defaultIntent, options: nil) else {
            fatalError("Could not convert to color space")
        }
        guard let components = converted.components else {
            fatalError("Could not get components")
        }
        var bytes = components.map { UInt8($0 / 255) }

        return try bytes.withUnsafeMutableBytes { buffer in
            let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            let context = CGContext(data: try buffer.baseAddress.safelyUnwrap(BaseError.generic("TODO")), width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo)
            guard let image = context?.makeImage() else {
                fatalError("Could not make image.")
            }
            return image
        }
    }
}
