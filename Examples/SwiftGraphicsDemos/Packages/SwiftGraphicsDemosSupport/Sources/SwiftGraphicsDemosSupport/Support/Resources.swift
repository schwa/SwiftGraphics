import Foundation
import MetalKit

// TODO: all this is very experimental.

protocol ResourceProtocol: Hashable, Sendable {
}

extension ResourceProtocol {
    func `as`(_ type: any URLProviding.Type) -> (any URLProviding)? {
        self as? any URLProviding
    }
}

protocol URLProviding: ResourceProtocol {
    var url: URL { get throws }
}

protocol SynchronousLoadable: ResourceProtocol {
    associatedtype Content
    associatedtype Parameter
    func load(_ parameter: Parameter) throws -> Content
}

extension SynchronousLoadable where Parameter == () {
    func load() throws -> Content {
        try load(())
    }
}

protocol AsynchronousLoadable: ResourceProtocol {
    associatedtype Content // TODO: Sendable?
    associatedtype Parameter
    func load(_ parameter: Parameter) async throws -> Content
}

extension AsynchronousLoadable where Parameter == () {
    func load() async throws -> Content {
        try await load(())
    }
}

// MARK: -

enum BundleReference: Hashable, Sendable {
    enum Error: Swift.Error {
        case missingBundle
    }

    case main
    case byURL(URL)
    case byIdentifier(String)
    case bundle(Bundle)
}

extension BundleReference {
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

struct BundleResourceReference {
    var bundle: BundleReference
    var name: String
    var `extension`: String?

    init(bundle: BundleReference, name: String, extension: String? = nil) {
        self.bundle = bundle
        self.name = name
        self.extension = `extension`
    }

    enum Error: Swift.Error {
        case missingResource
    }

    var exists: Bool {
        (try? bundle.bundle.url(forResource: name, withExtension: `extension`)) != nil
    }

    var url: URL {
        get throws {
            guard let url = try bundle.bundle.url(forResource: name, withExtension: `extension`) else {
                throw Error.missingResource
            }
            return url
        }
    }
}

extension BundleReference {
    func resource(named name: String, withExtension extension: String?) -> BundleResourceReference {
        BundleResourceReference(bundle: self, name: name, extension: `extension`)
    }
}

// MARK: -

extension BundleResourceReference: URLProviding {
}
