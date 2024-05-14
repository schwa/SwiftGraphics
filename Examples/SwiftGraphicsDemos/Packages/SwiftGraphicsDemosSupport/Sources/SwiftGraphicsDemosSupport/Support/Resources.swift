import Foundation
import MetalKit

// TODO: all this is very experimental.

public protocol ResourceProtocol: Hashable, Sendable {
}

public extension ResourceProtocol {
    func `as`(_ type: any URLProviding.Type) -> (any URLProviding)? {
        self as? any URLProviding
    }
}

public protocol URLProviding: ResourceProtocol {
    var url: URL { get throws }
}

public protocol SynchronousLoadable: ResourceProtocol {
    associatedtype Content
    associatedtype Parameter
    func load(_ parameter: Parameter) throws -> Content
}

public extension SynchronousLoadable where Parameter == () {
    func load() throws -> Content {
        try load(())
    }
}

public protocol AsynchronousLoadable: ResourceProtocol {
    associatedtype Content // TODO: Sendable?
    associatedtype Parameter
    func load(_ parameter: Parameter) async throws -> Content
}

public extension AsynchronousLoadable where Parameter == () {
    func load() async throws -> Content {
        try await load(())
    }
}

// MARK: -

public enum BundleReference: Hashable, Sendable {
    enum Error: Swift.Error {
        case missingBundle
    }

    case main
    case byURL(URL)
    case byIdentifier(String)
    case bundle(Bundle)
}

public extension BundleReference {
    var exists: Bool {
        switch self {
        case .main:
            true
        case .byURL(let url):
            Bundle(url: url) != nil
        case .byIdentifier(let identifier):
            Bundle(identifier: identifier) != nil
        case .bundle(let bundle):
            true
        }
    }

    var bundle: Bundle {
        get throws {
            switch self {
            case .main:
                return Bundle.main
            case .byURL(let url):
                guard let bundle = Bundle(url: url) else {
                    throw Error.missingBundle
                }
                return bundle
            case .byIdentifier(let identifier):
                guard let bundle = Bundle(identifier: identifier) else {
                    throw Error.missingBundle
                }
                return bundle
            case .bundle(let bundle):
                return bundle
            }
        }
    }
}

// MARK: -

public struct BundleResourceReference {
    public var bundle: BundleReference
    public var name: String
    public var `extension`: String?

    public init(bundle: BundleReference, name: String, extension: String? = nil) {
        self.bundle = bundle
        self.name = name
        self.extension = `extension`
    }

    enum Error: Swift.Error {
        case missingResource
    }

    public var exists: Bool {
        (try? bundle.bundle.url(forResource: name, withExtension: `extension`)) != nil
    }

    public var url: URL {
        get throws {
            guard let url = try bundle.bundle.url(forResource: name, withExtension: `extension`) else {
                throw Error.missingResource
            }
            return url
        }
    }
}

public extension BundleReference {
    func resource(named name: String, withExtension extension: String?) -> BundleResourceReference {
        BundleResourceReference(bundle: self, name: name, extension: `extension`)
    }
}

// MARK: -

extension BundleResourceReference: URLProviding {
}
