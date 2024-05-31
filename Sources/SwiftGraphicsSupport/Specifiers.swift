import Foundation
import MetalKit
import ModelIO
import os

public enum BundleSpecifier: Sendable, Equatable, Hashable {
    case direct(Bundle)
    case fileURL(URL)
    case main

    public func resolve() -> Bundle? {
        switch self {
        case .direct(let bundle):
            return bundle

        case .fileURL(let url):
            return Bundle(url: url)

        case .main:
            return .main
        }
    }
}

extension BundleSpecifier: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .direct(let direct):
            ".direct(\(direct))"
        case .fileURL(let url):
            ".url(\"\(url.standardizedFileURL)\")"
        case .main:
            ".main"
        }
    }
}

// MARK: -

public struct BundleResourceSpecifier: Sendable, Equatable, Hashable {
    var bundle: BundleSpecifier
    var name: String
    var `extension`: String?

    public init(bundle: BundleSpecifier, name: String, extension: String? = nil) {
        self.bundle = bundle
        self.name = name
        self.extension = `extension`
    }

    public func resolve() throws -> URL? {
        guard let bundle = bundle.resolve() else {
            return nil
        }
        return bundle.url(forResource: name, withExtension: `extension`)
    }
}

extension BundleResourceSpecifier: CustomDebugStringConvertible {
    public var debugDescription: String {
        "BundleResourceSpecifier(bundle: \(bundle), name: \"\(name)\(`extension`.map({ ".\($0)" }) ?? "")\")"
    }
}

// MARK: -

public struct MeshSpecifier: Equatable {
    private enum Content: Equatable {
        case direct(MTKMesh)
        case fileURL(URL)
        case bundleResource(BundleResourceSpecifier)
//        case meshConvertable(MDLMeshConvertable)
    }
    private var content: Content

    public static func direct(_ mesh: MTKMesh) -> Self {
        .init(content: .direct(mesh))
    }

    public static func fileURL(_ url: URL) -> Self {
        precondition(url.scheme == "file")
        return .init(content: .fileURL(url))
    }

    public static func bundleResource(_ resource: BundleResourceSpecifier) -> Self {
        .init(content: .bundleResource(resource))
    }

    public func load(device: MTLDevice, vertexDescriptor: MDLVertexDescriptor) throws -> MTKMesh {
        let mesh: MTKMesh
        switch content {
        case .direct(let direct):
            mesh = direct
            assert(mesh.vertexDescriptor == vertexDescriptor) // TODO: I am not sure this works.
        case .fileURL(let url):
            mesh = try load(url: url, device: device, vertexDescriptor: vertexDescriptor)

        case .bundleResource(let resource):
            guard let url = try resource.resolve() else {
                fatalError()
            }
            mesh = try load(url: url, device: device, vertexDescriptor: vertexDescriptor)

//        case .meshConvertable(let meshConvertable):
//
        }
        return mesh
    }

    // TODO: Use vertex descriptor.
    private func load(url: URL, device: MTLDevice, vertexDescriptor: MDLVertexDescriptor) throws -> MTKMesh {
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: url, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        guard let mdlMesh = asset.object(at: 0) as? MDLMesh else {
            fatalError()
        }
        return try MTKMesh(mesh: mdlMesh, device: device)
    }
}

extension MeshSpecifier: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch content {
        case .direct:
            "MeshSpecifier.direct(...)"
        case .fileURL(let url):
            "MeshSpecifier.fileURL(\"\(url.standardizedFileURL)\")"
        case .bundleResource(let bundleResource):
            "MeshSpecifier.bundleResource(\(bundleResource))"
//        case .meshConvertable:
//            "MeshSpecifier.meshConvertable(...)"
        }
    }
}

extension MeshSpecifier {
    var fileURL: URL? {
        switch content {
        case .fileURL(let url):
            return url
        case .bundleResource(let resource):
            return try? resource.resolve()
        default:
            return nil
        }
    }
}

// MARK: -

public struct TextureSpecifier: Equatable, Sendable, Hashable {
    // TODO: We can make NewTextureSpecifier an enum now that we just have content
    private enum Content: Equatable, Sendable, Hashable {
        case direct(TextureBox)
        case fileURL(URL)
        case bundleResource(BundleResourceSpecifier)
        case color(CGColor)
    }
    private var content: Content

    public static func direct(_ texture: MTLTexture) -> Self {
        .init(content: .direct(.init(texture)))
    }

    public static func fileURL(_ url: URL) -> Self {
        .init(content: .fileURL(url))
    }

    public static func bundleResource(_ resource: BundleResourceSpecifier) -> Self {
        .init(content: .bundleResource(resource))
    }

    public static func color(_ color: CGColor) -> Self {
        .init(content: .color(color))
    }

    // TODO: Make async

    public func load(textureLoader: MTKTextureLoader, scaleFactor: CGFloat, options: [MTKTextureLoader.Option: Any]?) throws -> MTLTexture {
        switch content {
        case .direct(let texture):
            return texture.texture

        case .fileURL(let url):
            return try textureLoader.newTexture(URL: url, options: options)

        case .bundleResource(let resource):
            let texture: MTLTexture
            if resource.name.contains("/") {
                guard let url = try resource.resolve() else {
                    fatalError()
                }
                texture = try textureLoader.newTexture(URL: url, options: options)
            }
            else {
                texture = try textureLoader.newTexture(name: resource.name, scaleFactor: scaleFactor, bundle: resource.bundle.resolve(), options: options)
            }
            return texture

        case .color(let color):
            return try textureLoader.newTexture(for: color, options: options)
        }
    }
}

extension TextureSpecifier {
    var fileURL: URL? {
        switch content {
        case .fileURL(let url):
            return url
        case .bundleResource(let resource):
            return try? resource.resolve()
        default:
            return nil
        }
    }
}

public extension TextureSpecifier {
    static let debugTexture = TextureSpecifier.bundleResource(.init(bundle: .main, name: "DebugTexture"))
}

extension TextureSpecifier: CustomDebugStringConvertible {
public var debugDescription: String {
    switch content {
    case .direct:
        ".direct(**texture**)"
    case .fileURL(let url):
        ".fileURL(\"\(url.standardizedFileURL)\")"
    case .bundleResource(let bundleResource):
        ".bundleResource(\(bundleResource))"
    case .color(let color):
        ".color(\(color))"
    }
}
}

// MARK: -

// A box that allows MTLTextures to become Equatable and Hashable.
struct TextureBox: Equatable, Hashable {
    var texture: MTLTexture

    init(_ texture: MTLTexture) {
        self.texture = texture
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.texture === rhs.texture
    }

    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(texture).hash(into: &hasher)
    }
}
