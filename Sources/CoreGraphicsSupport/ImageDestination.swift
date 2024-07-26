import BaseSupport
import Foundation
import ImageIO
import UniformTypeIdentifiers

public struct ImageDestination {
    public enum Error: Swift.Error {
        case unknownPathExtension
        case typeNotSupportedByImageIO
        case finalizeFailed
    }

    private var destination: CGImageDestination

    public init(url: URL, type: UTType? = nil, count: Int = 1) throws {
        let type = try type ?? Self.type(for: url)

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, count, nil) else {
            throw BaseError.resourceCreationFailure
        }
        self.destination = destination
    }

    public func addImage(_ image: CGImage, metadata: CGImageMetadata? = nil, options: CFDictionary? = nil) {
        CGImageDestinationAddImageAndMetadata(destination, image, metadata, options)
    }

    public func finalize() throws {
        if CGImageDestinationFinalize(destination) == false {
            throw Error.finalizeFailed
        }
    }

    // MARK: -

    public static var typeIdentifiers: Set<UTType> {
        guard let typeIdentifiers = CGImageDestinationCopyTypeIdentifiers() as? [String] else {
            fatalError(BaseError.resourceCreationFailure)
        }
        return Set(typeIdentifiers.compactMap { UTType($0) })
    }

    public static func type(for url: URL) throws -> UTType {
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            throw Error.unknownPathExtension
        }
        if typeIdentifiers.contains(type) == false {
            throw Error.unknownPathExtension
        }
        return type
    }
}

// MARK: -

public extension ImageDestination {
    static func write(image: CGImage, to url: URL, type: UTType? = nil, metadata: CGImageMetadata? = nil, options: CFDictionary? = nil) throws {
        let destination = try ImageDestination(url: url, type: type)
        destination.addImage(image, metadata: metadata, options: options)
        try destination.finalize()
    }
}

// MARK: -

public extension CGImage {
    func write(to url: URL, type: UTType? = nil, metadata: CGImageMetadata? = nil, options: CFDictionary? = nil) throws {
        try ImageDestination.write(image: self, to: url, type: type, metadata: metadata, options: options)
    }
}
