#if os(macOS)
    import AppKit
#endif

#if os(iOS) || os(tvOS)
    import UIKit
#endif

public struct Gradient<T, R> {
    public let stops: [(stop: Double, value: T)]

    public typealias Blend = (_ from: T, _ to: T, _ weight: Double) -> R

    public var blend: Blend

    // Assume stops are normalized

    public init(stops: [(stop: Double, value: T)], blend: @escaping Blend) {
        self.stops = stops
        self.blend = blend
    }

    public init(values: [T], blend: @escaping Blend) {
        stops = values.enumerated().map { offset, element in
            (stop: Double(offset) / Double(values.count - 1), value: element)
        }
        self.blend = blend
    }

    public func value(at fraction: Double) -> R {
        let maybeIndex = stops.firstIndex { stop, _ -> Bool in
            fraction < stop
        }

        let index = maybeIndex ?? stops.endIndex - 1

        let first = stops[index - 1]
        let second = stops[index]

        let weight = (fraction - first.stop) / (second.stop - first.stop)

        return blend(first.value, second.value, weight)
    }
}

#if os(macOS)
    public extension NSColor {
        convenience init(_ value: UInt32) {
            let bytes = stride(from: 16, through: 0, by: -8).reduce(into: []) { accumulator, shift in
                accumulator += [UInt8((value >> shift) & 0xFF)]
            }
            let channels = bytes.map {
                CGFloat($0) / 255
            }
            self.init(deviceRed: channels[0], green: channels[1], blue: channels[2], alpha: 1.0)
        }
    }

    public func blend(_ from: NSColor, _ to: NSColor, weight: Double) -> NSColor {
        from.blended(withFraction: CGFloat(weight), of: to)!
    }

    public func hueBlend(_ from: CGFloat, _ to: CGFloat, weight: Double) -> NSColor {
        let hue = ((to - from) * CGFloat(weight) + from).truncatingRemainder(dividingBy: 1.0)
        return NSColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }
#endif

#if os(iOS)
    public func hueBlend(_ from: CGFloat, _ to: CGFloat, weight: Double) -> UIColor {
        let hue = ((to - from) * CGFloat(weight) + from).truncatingRemainder(dividingBy: 1.0)
        return UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }
#endif
