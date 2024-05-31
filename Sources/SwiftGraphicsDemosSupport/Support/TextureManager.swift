import MetalKit

// TODO: Deprecate?
class TextureManager {
    struct Options {
        var allocateMipMaps = false
        var generateMipmaps = false
        var SRGB = false
        var textureUsage: MTLTextureUsage = .shaderRead
        var textureCPUCacheMode: MTLCPUCacheMode = .defaultCache
        var textureStorageMode: MTLStorageMode = .shared
        var cubeLayout: MTKTextureLoader.CubeLayout?
        var origin: MTKTextureLoader.Origin?
        var loadAsArray = false

        init() {
        }
    }

    private let device: MTLDevice
    private let textureLoader: MTKTextureLoader
    private let cache: Cache<AnyHashable, MTLTexture>

    init(device: MTLDevice) {
        self.device = device
        textureLoader = MTKTextureLoader(device: device)
        cache = Cache()
    }

    func texture(for resource: some ResourceProtocol, options: Options = Options()) throws -> MTLTexture {
        try cache.get(key: resource) {
            try textureLoader.newTexture(resource: resource, options: .init(options))
        }
    }
}

extension TextureManager.Options: Hashable {
    func hash(into hasher: inout Hasher) {
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

extension [MTKTextureLoader.Option: Any] {
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

extension MTKTextureLoader {
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
            fatalError("Unable to load texture.")
        }
    }

    func newTexture(resource: BundleResourceReference, options: [Option: Any]? = nil) throws -> MTLTexture {
        // TODO: Scale factor.
        try newTexture(name: resource.name, scaleFactor: 1.0, bundle: resource.bundle.bundle, options: options)
    }

    func newTexture(resource: some URLProviding, options: [Option: Any]? = nil) throws -> MTLTexture {
        let url = try resource.url
        return try newTexture(URL: url, options: options)
    }

    func newTexture(resource: some URLProviding, options: [Option: Any]? = nil) async throws -> MTLTexture {
        let url = try resource.url
        return try await newTexture(URL: url, options: options)
    }

    func newTexture<Resource>(resource: Resource, options: [Option: Any]? = nil) throws -> MTLTexture where Resource: SynchronousLoadable, Resource.Parameter == (), Resource.Content == Data {
        let data = try Data(resource.load())
        return try newTexture(data: data, options: options)
    }

    func newTexture<Resource>(resource: Resource, options: [Option: Any]? = nil) async throws -> MTLTexture where Resource: AsynchronousLoadable, Resource.Parameter == (), Resource.Content == Data {
        let data = try await Data(resource.load())
        return try await newTexture(data: data, options: options)
    }
}
