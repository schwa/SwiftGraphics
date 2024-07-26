import BaseSupport
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

#if os(macOS)
import AppKit

public extension CGImage {
    static func image(contentsOf url: URL) throws -> CGImage {
        guard let nsImage = NSImage(contentsOf: url) else {
            throw BaseError.inputOutputFailure
        }
        return nsImage.cgImage
    }
}
#endif // os(macOS)
