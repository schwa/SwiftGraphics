import MetalKit

public class TextureManager {
    public struct Options {
        public var allocateMipMaps = false
        public var generateMipmaps = false
        public var SRGB = false
        public var textureUsage: MTLTextureUsage = .shaderRead
        public var textureCPUCacheMode: MTLCPUCacheMode = .defaultCache
        public var textureStorageMode: MTLStorageMode = .shared
        public var cubeLayout: MTKTextureLoader.CubeLayout?
        public var origin: MTKTextureLoader.Origin?
        public var loadAsArray = false

        public init() {
        }
    }

    private let device: MTLDevice
    private let textureLoader: MTKTextureLoader
    private let cache: Cache<AnyHashable, MTLTexture>

    public init(device: MTLDevice) {
        self.device = device
        self.textureLoader = MTKTextureLoader(device: device)
        self.cache = Cache()
    }

    public func texture(for resource: some ResourceProtocol, options: Options = Options()) throws -> MTLTexture {
        return try cache.get(key: resource) {
            return try textureLoader.newTexture(resource: resource, options: .init(options))
        }
    }
}

extension TextureManager.Options: Hashable {
    public func hash(into hasher: inout Hasher) {
        allocateMipMaps.hash(into: &hasher)
        generateMipmaps.hash(into: &hasher)
        SRGB.hash(into: &hasher)
        textureUsage.rawValue.hash(into: &hasher)
        textureCPUCacheMode.hash(into: &hasher)
        textureStorageMode.rawValue.hash(into: &hasher)
        cubeLayout.hash(into: &hasher)
        origin.hash(into: &hasher)
        loadAsArray.hash(into: &hasher)
    }
}

extension Dictionary where Key == MTKTextureLoader.Option, Value == Any {
    init(_ options: TextureManager.Options) {
        self = [:]
        self[.allocateMipmaps] = options.allocateMipMaps
        self[.generateMipmaps] = options.generateMipmaps
        self[.SRGB] = options.SRGB
        self[.textureUsage] = options.textureUsage.rawValue
        self[.textureCPUCacheMode] = options.textureCPUCacheMode.rawValue
        self[.textureStorageMode] = options.textureStorageMode.rawValue
        if let cubeLayout = options.cubeLayout {
            self[.cubeLayout] = cubeLayout.rawValue
        }
        if let origin = options.origin {
            self[.origin] = origin.rawValue
        }
        self[.loadAsArray] = options.loadAsArray
    }
}

public extension MTKTextureLoader {
    func newTexture(resource: some ResourceProtocol, options: [Option: Any]? = nil) throws -> MTLTexture {
        if let resource = resource as? BundleResourceReference {
            return try newTexture(resource: resource, options: options)
        }

        if let resource = resource as? any URLProviding {
            return try newTexture(resource: resource, options: options)
        }
        else if let resource = resource as? any SynchronousLoadable {
            return try newTexture(resource: resource, options: options)
        }
        else {
            fatalError()
        }
    }

    func newTexture(resource: BundleResourceReference, options: [Option: Any]? = nil) throws -> MTLTexture {
        // TODO: Scale factor.
        return try newTexture(name: resource.name, scaleFactor: 1.0, bundle: resource.bundle.bundle, options: options)
    }

    func newTexture(resource: some URLProviding, options: [Option: Any]? = nil) throws -> MTLTexture {
        let url = try resource.url
        return try newTexture(URL: url, options: options)
    }

    func newTexture(resource: some URLProviding, options: [Option: Any]? = nil) async throws -> MTLTexture {
        let url = try resource.url
        return try await newTexture(URL: url, options: options)
    }

    func newTexture <Resource>(resource: Resource, options: [Option: Any]? = nil) throws -> MTLTexture where Resource: SynchronousLoadable, Resource.Parameter == (), Resource.Content == Data {
        let data = Data(try resource.load())
        return try newTexture(data: data, options: options)
    }

    func newTexture <Resource>(resource: Resource, options: [Option: Any]? = nil) async throws -> MTLTexture where Resource: AsynchronousLoadable, Resource.Parameter == (), Resource.Content == Data {
        let data = Data(try await resource.load())
        return try await newTexture(data: data, options: options)
    }
}
