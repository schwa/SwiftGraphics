import CoreGraphics
import simd

#if os(macOS)
    import AppKit

    public extension SIMD4 where Scalar: BinaryFloatingPoint {
        /// Create a SIMD4 with red, green, blue, alpha components of an NSColor
        init(_ color: NSColor) {
            self = [Scalar(color.redComponent), Scalar(color.greenComponent), Scalar(color.blueComponent), Scalar(color.alphaComponent)]
        }
    }

    public extension NSColor {
        /// Create a NSColor from a SIMD4 containing floating point red, green, blue and alpha channels
        convenience init(_ color: SIMD4<some BinaryFloatingPoint>) {
            let color = color.map { CGFloat($0) }
            self.init(red: color[0], green: color[1], blue: color[2], alpha: color[3])
        }
    }
#endif

public extension SIMD3 where Scalar: BinaryFloatingPoint {
    /// Create a SIMD4 with red, green and blue components of an CGColor
    @available(*, deprecated, message: "Do not use until colorspace issues are resolved.")
    init(_ cgColor: CGColor) {
        // TODO: Use linear color space. Piggy back of SIMD4
        let components = cgColor.components!.map { Scalar($0) }
        assert(components.count >= 3)
        self = SIMD3(Array(components[..<3]))
    }

    @available(*, deprecated, message: "Do not use until colorspace issues are resolved.")
    var cgColor: CGColor {
        // TODO: Use linear color space. Piggy back of SIMD4
        #if os(macOS)
            return CGColor(red: CGFloat(self[0]), green: CGFloat(self[1]), blue: CGFloat(self[2]), alpha: 1)
        #else
            fatalError("Unimplemented")
        #endif
    }
}

public extension SIMD4 where Scalar: BinaryFloatingPoint {
    @available(*, deprecated, message: "Do not use until colorspace issues are resolved.")
    var cgColor: CGColor {
        // TODO: use linear color space
        #if os(macOS)
            return CGColor(red: CGFloat(self[0]), green: CGFloat(self[1]), blue: CGFloat(self[2]), alpha: CGFloat(self[3]))
        #else
            fatalError("Unimplemented")
        #endif
    }
}
