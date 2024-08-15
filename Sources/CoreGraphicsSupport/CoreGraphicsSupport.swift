import BaseSupport
import CoreGraphics

public extension CGColor {
    func makeImage(colorSpace: CGColorSpace? = nil) throws -> CGImage {
        guard let colorSpace = colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) else {
            throw BaseError.error(.resourceCreationFailure)
        }
        guard let converted = converted(to: colorSpace, intent: .defaultIntent, options: nil) else {
            throw BaseError.error(.resourceCreationFailure)
        }
        guard let components = converted.components else {
            throw BaseError.error(.resourceCreationFailure)
        }
        var bytes = components.map { UInt8($0 / 255) }

        return try bytes.withUnsafeMutableBytes { buffer in
            let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            let context = CGContext(data: try buffer.baseAddress.safelyUnwrap(BaseError.resourceCreationFailure), width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo)
            guard let image = context?.makeImage() else {
                throw BaseError.error(.resourceCreationFailure)
            }
            return image
        }
    }
}

public func wrap(_ point: CGPoint, to rect: CGRect) -> CGPoint {
    CGPoint(
        x: wrap(point.x, to: rect.minX ... rect.maxX),
        y: wrap(point.y, to: rect.minY ... rect.maxY)
    )
}
