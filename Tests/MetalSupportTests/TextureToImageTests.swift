import Algorithms
import BaseSupport
import CoreGraphicsSupport
import Metal
import MetalUnsafeConformances
import MetalSupport
import MetalKit
import Testing
import simd
import SwiftUI
import os
import MetalPerformanceShaders

@Test
@MainActor
func testImages() throws {
    guard let sourceImage = try ImageRenderer(content: TestCard()).cgImage?.convert(to: .rgba8) else {
        throw BaseError.error(.resourceCreationFailure)
    }
    #expect(sourceImage.alphaInfo == .premultipliedLast)

    let sourceTexture = try MTLCreateSystemDefaultDevice()!.newTexture(with: sourceImage)
    #expect(sourceTexture.pixelFormat == .rgba8Unorm)

    let pixelFormats: [(MTLPixelFormat, CGColorSpace)] = [
        (.rgba8Unorm, CGColorSpaceCreateDeviceRGB()),
        (.bgra8Unorm, CGColorSpaceCreateDeviceRGB()),
    ]

    for (pixelFormat, colorSpace) in pixelFormats {
        let convertedTexture = try sourceTexture.convert(pixelFormat: pixelFormat, destinationColorSpace: colorSpace, sourceAlpha: .premultiplied, destinationAlpha: .premultiplied)
        let outImage = try convertedTexture.cgImage()
        let imageComparator = ImageComparator(a: sourceImage, b: outImage)
        #expect(try imageComparator.compare(background: .white))
        #expect(try imageComparator.compare(background: .black))
        #expect(try imageComparator.compare(background: .clear))

    }
}

struct ImageComparator {
    var a: CGImage
    var b: CGImage
    var writeToTempOnFailure: Bool = true
    var logger: Logger?

    func compare(background: CGColor) throws -> Bool {
        let bitmapDefinition = BitmapDefinition(width: max(a.width, b.width), height: max(a.height, b.height), pixelFormat: .rgba8)
        let contextA = try CGContext.bitmapContext(definition: bitmapDefinition, color: background, image: a)
        let contextB = try CGContext.bitmapContext(definition: bitmapDefinition, color: background, image: b)
        let pixelsA = contextA.pixels
        let pixelsB = contextB.pixels
        if pixelsA != pixelsB {
            if let logger {
                let differences = zip(pixelsA, pixelsB).filter { $0 != $1 }
                let rgbDifferences = zip(pixelsA.map(\.rgb), pixelsB.map(\.rgb)).filter { $0 != $1 }
                logger.info("\(pixelsA.count) pixels, \(differences.count) differences, \(rgbDifferences.count) rgb differences")
                logger.info("First differing pixel: \(String(describing: differences.first))")
            }
            if writeToTempOnFailure {
                guard let imageA = contextA.makeImage() else {
                    throw BaseError.error(.resourceCreationFailure)
                }
                try imageA.write(to: URL(fileURLWithPath: "/tmp/testimage-a.png"))
                guard let imageB = contextB.makeImage() else {
                    throw BaseError.error(.resourceCreationFailure)
                }
                try imageB.write(to: URL(fileURLWithPath: "/tmp/testimage-b.png"))
            }
        }
        return pixelsA == pixelsB
    }
}

extension CGContext {

    var bounds: CGRect {
        CGRect(x: 0, y: 0, width: width, height: height)
    }

    static func bitmapContext(data: UnsafeMutableRawBufferPointer? = nil, definition: BitmapDefinition, color: CGColor? = nil, image: CGImage? = nil) throws -> CGContext {
        let context = try bitmapContext(data: data, definition: definition)
        if let color {
            context.setFillColor(color)
            context.fill([context.bounds])
        }
        if let image {
            context.draw(image, in: image.bounds)
        }
        return context
    }

    var pixels: [SIMD4<UInt8>] {
        guard let bytes = data else {
            fatalError(BaseError.resourceCreationFailure)
        }
        let buffer = UnsafeRawBufferPointer(start: bytes, count: bytesPerRow * height)
        return Array(buffer.bindMemory(to: SIMD4<UInt8>.self))
    }
}

extension CGImage {
    var data: Data {
        get throws {
            let context = try CGContext.bitmapContext(definition: bitmapDefinition)
            context.draw(self, in: bounds)
            guard let data = context.data else {
                throw BaseError.error(.resourceCreationFailure)
            }
            return Data(bytes: data, count: bytesPerRow * height)
        }
    }

    var bounds: CGRect {
        CGRect(x: 0, y: 0, width: width, height: height)
    }

    var bitmapDefinition: BitmapDefinition {
        .init(width: width, height: height, pixelFormat: pixelFormat)
    }

    var pixelFormat: PixelFormat {
        let numberOfComponents = bytesPerRow / (bitsPerComponent / 8) / width
        return PixelFormat(bitsPerComponent: bitsPerComponent, numberOfComponents: numberOfComponents, alphaInfo: alphaInfo, byteOrder: byteOrderInfo, colorSpace: colorSpace)
    }

    func convert(to pixelFormat: PixelFormat) throws -> CGImage {
        let bitmapDefinition = BitmapDefinition(width: width, height: height, pixelFormat: pixelFormat)
        let context = try CGContext.bitmapContext(definition: bitmapDefinition)
        context.draw(self, in: bounds)
        guard let converted = context.makeImage() else {
            throw BaseError.error(.resourceCreationFailure)
        }
        return converted
    }
}

extension MTLDevice {
    func newTexture(with url: URL, options: [MTKTextureLoader.Option : Any]? = nil) throws -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: self)
        return try textureLoader.newTexture(URL: url, options: options)
    }
}

struct TestCard: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            VStack(alignment: .leading) {
                Text("Colors & Alpha").font(.title)
                let colors: [String] = ["#000000", "#FFFFFF", "#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF"
                ]
                HStack {
                    ForEach(colors, id: \.self) { color in
                        VStack {
                            try! Color(string: color).frame(width: 50, height: 50)
                            Text(verbatim: color).font(.caption)
                        }
                    }
                }
                let opacities = [1.0, 0.9, 0.75, 0.5, 0.25, 0.125, 0.0625]
                VStack() {
                    ForEach(opacities, id: \.self) { opacity in
                        HStack {
                            Text(opacity, format: .number)
                                .font(.caption)
                                .frame(width: 40, alignment: .trailing)
                            ForEach(colors, id: \.self) { color in
                                try! Color(string: color, opacity: opacity).frame(width: 25, height: 25)
                            }
                        }
                    }
                }
            }
            .padding()
            .border(Color.black)
        }
        .border(Color.black)
        .frame(width: 1024, height: 1024)
    }
}

extension Color {
    public init(string: String, opacity: Double = 1.0) throws {
        let pattern = #/^#(?<red>[0-9a-fA-F]{2})(?<green>[0-9a-fA-F]{2})(?<blue>[0-9a-fA-F]{2})$/#

        guard let match = try pattern.firstMatch(in: string) else {
            throw BaseError.error(.parsingFailure)
        }
        guard let red = Int(match.output.red, radix: 16).map({ Double($0) / 255}) else {
            throw BaseError.error(.parsingFailure)
        }
        guard let green = Int(match.output.green, radix: 16).map({ Double($0) / 255}) else {
            throw BaseError.error(.parsingFailure)
        }
        guard let blue = Int(match.output.blue, radix: 16).map({ Double($0) / 255}) else {
            throw BaseError.error(.parsingFailure)
        }
        self = .init(red: red, green: green, blue: blue, opacity: opacity)
    }
}

extension Color: @retroactive ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        do {
            self = try Color(string: value)
        }
        catch {
            fatalError(error)
        }
    }
}
