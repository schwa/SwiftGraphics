import BaseSupport
import Foundation
@preconcurrency import Metal
import SwiftUI

// MARK: -

enum TextureResourceSpecifier: Sendable {
    case file(URL)
    case bundledResource(Bundle, String)
    case cgImage(CGImage)
    case texture(MTLTexture)

    static let resourceScheme = "x-resource"

    enum Error: Swift.Error {
        case invalidURL
        case missingBundle
        case invalidForm
    }
}

extension TextureResourceSpecifier: Equatable {
    static func == (lhs: TextureResourceSpecifier, rhs: TextureResourceSpecifier) -> Bool {
        switch (lhs, rhs) {
        case (.file(let lhs), .file(let rhs)):
            return lhs == rhs

        case (.bundledResource(let lhsBundle, let lhsName), .bundledResource(let rhsBundle, let rhsName)):
            return lhsBundle == rhsBundle && lhsName == rhsName

        case (.cgImage(let lhs), .cgImage(let rhs)):
            return lhs == rhs

        case (.texture(let lhs), .texture(let rhs)):
            return lhs === rhs

        default:
            return false
        }
    }
}

extension TextureResourceSpecifier: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .file(let url):
            url.hash(into: &hasher)

        case .bundledResource(let bundle, let name):
            bundle.hash(into: &hasher)
            name.hash(into: &hasher)

        case .cgImage(let image):
            image.hash(into: &hasher)

        case .texture(let texture):
            texture.hash.hash(into: &hasher)
        }
    }
}

extension TextureResourceSpecifier {
    init(_ url: URL) throws {
        switch url.scheme {
        case "file":
            self = .file(url)

        case Self.resourceScheme:
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw TextureResourceSpecifier.Error.invalidURL
            }
            let bundle: Bundle
            if let bundleIdentifier = components.queryItems?.first(where: { $0.name == "bundle-identifier" })?.value {
                guard let b = Bundle(identifier: bundleIdentifier) else {
                    throw TextureResourceSpecifier.Error.missingBundle
                }
                bundle = b
            } else {
                bundle = Bundle.main
            }
            let name = String(components.path.split(separator: "/").last!)
            self = .bundledResource(bundle, name)

        default:
            throw TextureResourceSpecifier.Error.invalidURL
        }
    }

    var url: URL? {
        get throws {
            switch self {
            case let .file(url):
                return url

            case let .bundledResource(bundle, name):
                var components = URLComponents()
                components.scheme = Self.resourceScheme
                components.path = name
                if bundle !== Bundle.main {
                    components.queryItems = [
                        .init(name: "bundle-identifier", value: bundle.bundleIdentifier),
                    ]
                }
                guard let url = components.url else {
                    throw TextureResourceSpecifier.Error.invalidURL
                }
                return url

            default:
                return nil
            }
        }
    }
}

extension TextureResourceSpecifier {
    init(_ urlString: String) throws {
        try self.init(URL(string: urlString)!)
    }
}

extension TextureResourceSpecifier: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        do {
            try self.init(value)
        }
        catch {
            fatalError("Failed to create TextureResourceSpecifier from `value`")
        }
    }
}

extension TextureResourceSpecifier: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let url = try container.decode(URL.self)
        try self.init(url)
    }

    func encode(to encoder: Encoder) throws {
        unimplemented()
    }
}

// MARK: -

protocol InitWithTextureResourceSpecifier {
    init(_ specifier: TextureResourceSpecifier) throws
}

extension Image: InitWithTextureResourceSpecifier {
    init(_ specifier: TextureResourceSpecifier) throws {
        switch specifier {
        case let .file(url):
            self = try Image(url: url)

        case let .bundledResource(bundle, name):
            self = Image(name, bundle: bundle)

        case let .cgImage(cgImage):
            #if os(macOS)
            let nsImage = NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
            self = Image(nsImage: nsImage)
            #elseif os(iOS)
            let uiImage = UIImage(cgImage: cgImage)
            self = Image(uiImage: uiImage)
            #endif

        default:
            throw TextureResourceSpecifier.Error.invalidForm
        }
    }
}
