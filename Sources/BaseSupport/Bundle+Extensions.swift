import Foundation
import UniformTypeIdentifiers
import RegexBuilder

public extension Bundle {
    func urls(withExtension extension: String) throws -> [URL] {
        guard let resourceURL else {
            return []
        }
        return try FileManager().contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil).filter {
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

    @available(*, deprecated, message: "Deprecated")
    func url <Pattern>(forResourceMatching pattern: Pattern, withExtension extension: String, recursive: Bool) -> URL? where Pattern: RegexComponent {
        guard let resourceURL else {
            return nil
        }
        do {
            let match = try FileManager().contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil).first {
                $0.lastPathComponent.wholeMatch(of: pattern) != nil
            }
            if let match {
                return match
            }
            if recursive {
                for bundle in childBundles {
                    if let url = bundle.url(forResourceMatching: pattern, withExtension: `extension`, recursive: false) {
                        return url
                    }
                }
                for bundle in childBundles {
                    if let url = bundle.url(forResourceMatching: pattern, withExtension: `extension`, recursive: true) {
                        return url
                    }
                }
            }
            return nil
        }
        catch {
            return nil
        }
    }

    @available(*, deprecated, message: "Deprecated")
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

    @available(*, deprecated, message: "Deprecated")
    func url(forResource resource: String?, withExtension extension: String?) throws -> URL {
        guard let url = url(forResource: resource, withExtension: `extension`) else {
            throw BaseError.error(.resourceCreationFailure)
        }
        return url
    }

    @available(*, deprecated, message: "Deprecated")
    static func bundle(forProject project: String, target: String) -> Bundle? {
        guard let url = Bundle.main.url(forResource: "\(project)_\(target)", withExtension: "bundle") else {
            return nil
        }
        return Bundle(url: url)
    }

    func bundle(forTarget target: String) -> Bundle? {
        let pattern = Regex {
            OneOrMore {
                /./
            }
            "_"
            target
            ".bundle"
        }
        return childBundles.first { bundle in
            bundle.bundleURL.lastPathComponent.firstMatch(of: pattern) != nil
        }
    }

    func bundle(forTarget target: String, recursive: Bool) -> Bundle? {
        if !recursive {
            return bundle(forTarget: target)
        }
        if let result = bundle(forTarget: target) {
            return result
        }
        else {
            return childBundles.compactMap { $0.bundle(forTarget: target, recursive: true) }.first
        }
    }

}
