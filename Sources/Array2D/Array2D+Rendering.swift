import Algorithms
import CoreGraphics
import CoreGraphicsSupport
import CoreGraphicsUnsafeConformances
import GenericGeometryBase

private extension Array2D {
    mutating func draw(image: CGImage, definition: BitmapDefinition) {
        flatStorage.withUnsafeMutableBytes { buffer in
            guard let context = CGContext.bitmapContext(data: buffer, definition: definition) else {
                fatalError("Could not create bitmap context")
            }
            context.draw(image, in: CGRect(width: CGFloat(image.width), height: CGFloat(image.height)))
        }
    }
}

// MARK: -

public extension Array2D where Element == Float {
    private var pixelFormat: PixelFormat {
        PixelFormat(bitsPerComponent: MemoryLayout<Element>.stride * 8, numberOfComponents: 1, alphaInfo: .none, byteOrder: .order32Little, useFloatComponents: true, colorSpace: CGColorSpace(name: CGColorSpace.linearGray)!)
    }

    init(cgImage: CGImage) {
        self = Array2D(repeating: Float.zero, size: [cgImage.width, cgImage.height])
        let definition = BitmapDefinition(width: cgImage.width, height: cgImage.height, pixelFormat: pixelFormat)
        draw(image: cgImage, definition: definition)
    }

    var cgImage: CGImage {
        flatStorage.withUnsafeBytes { bytes in
            let bytes = UnsafeMutableRawBufferPointer(mutating: bytes)
            let definition = BitmapDefinition(width: size.width, height: size.height, pixelFormat: pixelFormat)
            guard let bitmapContext = CGContext.bitmapContext(data: bytes, definition: definition) else {
                fatalError("Could not create bitmap context")
            }
            return bitmapContext.makeImage()!
        }
    }
}

// MARK: BinaryInteger

public extension Array2D where Element: BinaryInteger {
    var cgImage: CGImage {
        let colorspace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: 0)
        // CGBitmapInfo(alphaInfo: .none, useFloatComponents: false, byteOrderInfo: .orderDefault)
        let size = size
        return flatStorage.withUnsafeBytes { bytes in
            let bytes = UnsafeMutableRawBufferPointer(mutating: bytes)
            let bitsPerComponent = MemoryLayout<Element>.size * 8
            let bytesPerRow = MemoryLayout<Element>.stride * size.width
            guard let context = CGContext(data: bytes.baseAddress, width: size.width, height: size.height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorspace, bitmapInfo: bitmapInfo.rawValue) else {
                fatalError("Could not create context")
            }
            guard let image = context.makeImage() else {
                fatalError("Could not create image")
            }
            return image
        }
    }
}

public extension Array2D {
    func toCGImage(_ block: (Element) -> CGColor) -> CGImage {
        let definition = BitmapDefinition(width: size.width, height: size.height, pixelFormat: .rgba8)
        guard let bitmapContext = CGContext.bitmapContext(data: nil, definition: definition) else {
            fatalError("Could not create bitmap context")
        }
        render(in: bitmapContext, cellSize: [1, 1]) {
            block($0)
        }
        return bitmapContext.makeImage()!
    }
}

// MARK: UInt8

public extension Array2D where Element == SIMD4<UInt8> {
    init(cgImage: CGImage) {
        let size: IntSize = [cgImage.width, cgImage.height]

        let colorspace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(alphaInfo: .premultipliedLast, byteOrderInfo: CGImageByteOrderInfo.order32Big, useFloatComponents: false)
        guard let context = CGContext(data: nil, width: size.width, height: size.height, bitsPerComponent: 8, bytesPerRow: MemoryLayout<Element>.size * size.width, space: colorspace, bitmapInfo: bitmapInfo.rawValue) else {
            fatalError("Unimplemented")
        }
        context.setAllowsAntialiasing(false)
        context.draw(cgImage, in: CGRect(width: CGFloat(size.width), height: CGFloat(size.height)))

        let count = size.width * size.height
        let pointer = context.data!.bindMemory(to: Element.self, capacity: count)
        let buffer = UnsafeMutableBufferPointer(start: pointer, count: count)
        self.init(flatStorage: Array(buffer), size: size)
    }

    var cgImage: CGImage {
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(alphaInfo: .premultipliedLast, byteOrderInfo: CGImageByteOrderInfo.order32Big)
        let size = size

        return flatStorage.withUnsafeBytes { bytes in
            let bytes = UnsafeMutableRawPointer(mutating: bytes.baseAddress)
            guard let context = CGContext(data: bytes, width: size.width, height: size.height, bitsPerComponent: 8, bytesPerRow: MemoryLayout<Element>.size * size.width, space: colorspace, bitmapInfo: bitmapInfo.rawValue) else {
                fatalError("Unimplemented")
            }
            guard let image = context.makeImage() else {
                fatalError("Unimplemented")
            }
            return image
        }
    }
}

// MARK: CGContext

public extension Array2D {
    // TODO: Replace with methods on CGContext

    func render(in context: CGContext, cellSize: CGSize, dirtyRect: CGRect = .infinite, colorMapper: (Element) -> CGColor) {
        var lastColor: CGColor!
        for (index, value) in indexed() {
            let cellOrigin = CGPoint(x: CGFloat(index.x) * cellSize.width, y: CGFloat(index.y) * cellSize.height)
            let cellRect = CGRect(origin: cellOrigin, size: cellSize)
            if cellRect.intersects(dirtyRect) {
                let color = colorMapper(value)
                if color !== lastColor {
                    context.setFillColor(color)
                    lastColor = color
                }
                context.fill(cellRect)
            }
        }
    }
}

// public extension Array2D where Element: ColorConvertible {
//    // TODO: Replace with methods on CGContext
//    func render(in context: CGContext, cellSize: CGSize, dirtyRect: CGRect = .infinite) {
//        var lastColor: CGColor!
//        for (index, value) in indexed() {
//            let cellOrigin = CGPoint(x: CGFloat(index.x) * cellSize.width, y: CGFloat(index.y) * cellSize.height)
//            let cellRect = CGRect(origin: cellOrigin, size: cellSize)
//            if cellRect.intersects(dirtyRect) {
//                let color = value.color
//                if color !== lastColor {
//                    context.setFillColor(color)
//                    lastColor = color
//                }
//                context.fill(cellRect)
//            }
//        }
//    }
// }

public extension Array2D {
    // TODO: Replace with methods on CGContext
    func render(in context: CGContext, cellSize: CGSize, callback: (Element) -> CGColor) {
        for (index, value) in indexed() {
            let cellOrigin = CGPoint(x: CGFloat(index.x) * cellSize.width, y: CGFloat(index.y) * cellSize.height)
            let cellRect = CGRect(origin: cellOrigin, size: cellSize)
            let color = callback(value)
            context.setFillColor(color)
            context.fill(cellRect)
        }
    }
}

// MARK: RGBA
