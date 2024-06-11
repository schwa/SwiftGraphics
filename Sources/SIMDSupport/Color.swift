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
