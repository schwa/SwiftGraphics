import AppKit
import Compute
import CoreGraphics
import CoreGraphicsSupport
import Foundation
import Metal
import MetalSupport
import RenderKit

class StopWatch: CustomStringConvertible {
    var last: CFAbsoluteTime?

    var time: CFAbsoluteTime {
        let now = CFAbsoluteTimeGetCurrent()
        if last == nil {
            last = now
        }
        return now - last!
    }

    var description: String {
        "\(time)"
    }
}

func time(_ block: () -> Void) -> CFAbsoluteTime {
    let start = CFAbsoluteTimeGetCurrent()
    block()
    let end = CFAbsoluteTimeGetCurrent()
    return end - start
}

public func nextPowerOfTwo(_ value: Double) -> Double {
    let logValue = log2(Double(value))
    let nextPower = pow(2.0, ceil(logValue))
    return nextPower
}

public func nextPowerOfTwo(_ value: Int) -> Int {
    Int(nextPowerOfTwo(Double(value)))
}

extension Collection where Element: Comparable {
    var isSorted: Bool {
        zip(self, sorted()).allSatisfy { lhs, rhs in
            lhs == rhs
        }
    }
}

public extension MTLSize {
    init(width: Int) {
        self = MTLSize(width: width, height: 1, depth: 1)
    }
}

extension MTLTexture {
    func toString() -> String {
        assert(pixelFormat == .r8Uint)
        assert(depth == 1)

        let size = width * height * depth

        // TODO: Assumes width is aligned correctly
        var buffer = Array(repeating: UInt8.zero, count: size)

        buffer.withUnsafeMutableBytes { buffer in
            getBytes(buffer.baseAddress!, bytesPerRow: width, from: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: width, height: height, depth: depth)), mipmapLevel: 0)
        }

        var s = ""
        for row in 0 ..< height {
            let chunk = buffer[row * width ..< (row + 1) * width]
            s += chunk.map { String($0) }.joined()
            s += "\n"
        }

        return s
    }
}

extension CGImage {
    static func makeTestImage(width: Int, height: Int) -> CGImage? {
        guard let context = CGContext.bitmapContext(definition: .init(width: width, height: height, pixelFormat: .rgba8)) else {
            return nil
        }
        let rect = CGRect(width: CGFloat(width), height: CGFloat(height))
        let size2 = rect.size / 2
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill([CGRect(origin: rect.minXMinY, size: size2)])
        context.setFillColor(CGColor(red: 0, green: 1, blue: 0, alpha: 1))
        context.fill([CGRect(origin: rect.midXMinY, size: size2)])
        context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        context.fill([CGRect(origin: rect.minXMidY, size: size2)])

        var locations: [CGFloat] = [0, 1]
        let colors = [CGColor(red: 1, green: 1, blue: 1, alpha: 0), CGColor(red: 1, green: 1, blue: 1, alpha: 1)]
        let gradient = CGGradient(colorsSpace: context.colorSpace!, colors: colors as CFArray, locations: &locations)!

        context.clip(to: [CGRect(origin: rect.midXMidY, size: size2)])
        context.drawLinearGradient(gradient, start: rect.midXMidY, end: rect.maxXMaxY, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        return context.makeImage()
    }
}
