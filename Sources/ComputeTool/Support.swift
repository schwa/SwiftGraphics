import AppKit
import BaseSupport
import CoreGraphics
import CoreGraphicsSupport
import Foundation
import Metal

// swiftlint:disable force_unwrapping

// TODO: MOVE

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

extension Collection where Element: Comparable {
    var isSorted: Bool {
        zip(self, sorted()).allSatisfy { lhs, rhs in
            lhs == rhs
        }
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
    static func makeTestImage(width: Int, height: Int) throws -> CGImage {
        try makeTestImage(definition: .init(width: width, height: height, pixelFormat: .rgba8))
    }

    static func makeTestImage(definition: BitmapDefinition) throws -> CGImage {
        let context = try CGContext.bitmapContext(definition: definition)
        let rect = CGRect(width: CGFloat(definition.width), height: CGFloat(definition.height))
        func segment(color: CGColor, start: CGPoint, end: CGPoint) {
            context.saveGState()
            var locations: [CGFloat] = [0.333, 1]
            let colors = [color.withAlphaComponent(0), color]
            let gradient = CGGradient(colorsSpace: context.colorSpace!, colors: colors as CFArray, locations: &locations)!
            context.clip(to: [CGRect(points: (start, end))])
            context.drawLinearGradient(gradient, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            context.restoreGState()
        }
        segment(color: CGColor(red: 1, green: 0, blue: 0, alpha: 1), start: rect.minXMaxY, end: rect.midXMidY)
        segment(color: CGColor(red: 0, green: 1, blue: 0, alpha: 1), start: rect.maxXMaxY, end: rect.midXMidY)
        segment(color: CGColor(red: 0, green: 0, blue: 1, alpha: 1), start: rect.minXMinY, end: rect.midXMidY)
        segment(color: CGColor(red: 0, green: 0, blue: 0, alpha: 1), start: rect.maxXMinY, end: rect.midXMidY)
        guard let image = context.makeImage() else {
            throw BaseError.generic("Failed to create image")
        }
        return image
    }
}
