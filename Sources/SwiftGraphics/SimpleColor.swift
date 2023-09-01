import CoreGraphics
import Foundation
#if os(macOS)
    import AppKit
#elseif os(iOS) || os(tvOS)
    import UIKit
#endif

public struct SimpleColor {
    public let hue: CGFloat
    public let saturation: CGFloat
    public let brightness: CGFloat
    public let alpha: CGFloat

    public init(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.alpha = alpha
    }

    public var cgColor: CGColor {
        #if os(macOS)
            return NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha).cgColor
        #elseif os(iOS) || os(tvOS)
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha).cgColor
        #endif
    }
}
