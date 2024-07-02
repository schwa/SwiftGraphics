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

#if os(macOS)
public extension CGContext {
    func makeImage(size: CGSize) -> NSImage {
        let image = makeImage()!
        return NSImage(cgImage: image, size: size)
    }
}
#endif

public extension CGImage {
    var size: CGSize {
        CGSize(width: width, height: height)
    }

    var frame: CGRect {
        CGRect(x: 0, y: 0, width: width, height: height)
    }
}
