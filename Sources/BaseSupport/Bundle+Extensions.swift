import Foundation
import UniformTypeIdentifiers

public extension Bundle {
    func urls(withExtension extension: String) throws -> [URL] {
        try FileManager().contentsOfDirectory(at: resourceURL!, includingPropertiesForKeys: nil).filter {
            $0.pathExtension == `extension`
        }
    }

    func peerBundle(named name: String, withExtension extension: String? = nil) -> Bundle? {
        let parentDirectory = bundleURL.deletingLastPathComponent()
        if let `extension` {
            return Bundle(url: parentDirectory.appendingPathComponent(name + "." + `extension`))
        } else {
            return Bundle(url: parentDirectory.appendingPathComponent(name))
        }
    }

    var childBundles: [Bundle] {
        guard let resourceURL else {
            return []
        }
        let fileMananger = FileManager()
        let urls = (try? fileMananger.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: [.contentTypeKey], options: [])) ?? []
        return urls.filter { url in
            guard let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
                return false
            }
            return contentType.conforms(to: .bundle)
        }
        .compactMap { url in
            Bundle(url: url)
        }
    }

    func url(forResource name: String, withExtension extension: String, recursive: Bool) -> URL? {
        if let url = url(forResource: name, withExtension: `extension`) {
            return url
        }
        else {
            if recursive {
                for bundle in childBundles {
                    if let url = bundle.url(forResource: name, withExtension: `extension`) {
                        return url
                    }
                }
                for bundle in childBundles {
                    if let url = bundle.url(forResource: name, withExtension: `extension`, recursive: true) {
                        return url
                    }
                }
            }
        }
        return nil
    }

    func url(forResource resource: String?, withExtension extension: String?) throws -> URL {
        guard let url = url(forResource: resource, withExtension: `extension`) else {
            throw BaseError.error(.resourceCreationFailure)
        }
        return url
    }

    static func bundle(forProject project: String, target: String) -> Bundle? {
        let url = Bundle.main.url(forResource: "\(project)_\(target)", withExtension: "bundle")!
        return Bundle(url: url)
    }
}
