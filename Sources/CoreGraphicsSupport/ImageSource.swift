import Foundation
import ImageIO
import UniformTypeIdentifiers

public struct ImageSource {
    public enum ImageSourceError: Error {
        case initializationFailure
        case imageCreationFailure
        case thumbnailCreationFailure
    }

    @_spi(SPI)
    public let imageSource: CGImageSource

    public init(data: Data) throws {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ImageSourceError.initializationFailure
        }
        self.imageSource = imageSource
    }

    public init(url: URL) throws {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw ImageSourceError.initializationFailure
        }
        self.imageSource = imageSource
    }

    public var count: Int {
        CGImageSourceGetCount(imageSource)
    }

    public var contentType: UTType? {
        guard let identifier = CGImageSourceGetType(imageSource) as String? else {
            return nil
        }
        return UTType(identifier)
    }

    public func thumbnail(at index: Int) throws -> CGImage {
        let options = [kCGImageSourceCreateThumbnailFromImageIfAbsent: true]
        guard let image = CGImageSourceCreateThumbnailAtIndex(imageSource, index, options as CFDictionary) else {
            throw ImageSourceError.thumbnailCreationFailure
        }
        return image
    }

    public func image(at index: Int) throws -> CGImage {
        guard let image = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
            throw ImageSourceError.imageCreationFailure
        }
        return image
    }

    public func properties(at index: Int) throws -> [String: Any]? {
        CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as? [String: Any]
    }
}

public extension ImageSource {
    init(named name: String, bundle: Bundle = Bundle.main) throws {
        guard let url = bundle.url(forResource: name, withExtension: "png") else { // TODO:
            fatalError("Could not find image named \(name) in bundle \(bundle)")
        }
        self = try ImageSource(url: url)
    }
}

#if os(macOS)
import AppKit

public extension CGImage {
    static func image(contentsOf url: URL) throws -> CGImage {
        let nsImage = NSImage(contentsOf: url)! // TODO: Bang
        return nsImage.cgImage
    }
}

#elseif os(iOS) || os(tvOS)
import UIKit

public extension CGImage {
    @available(*, unavailable)
    static func image(contentsOf url: URL) throws -> CGImage {
        // TODO:
        fatalError("Unimplemented")
    }
}
#endif // os(macOS)
