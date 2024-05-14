import Metal

public enum MetalSupportError: Error {
    case illegalValue
}

func fatalError(_ error: Error) -> Never {
    fatalError("\(error)")
}

// TODO: Move
public extension MTLTextureDescriptor {
    convenience init(_ texture: MTLTexture) {
        self.init()
        textureType = texture.textureType
        pixelFormat = texture.pixelFormat
        width = texture.width
        height = texture.height
        depth = texture.depth
        mipmapLevelCount = texture.mipmapLevelCount
        sampleCount = texture.sampleCount
        arrayLength = texture.arrayLength
        resourceOptions = texture.resourceOptions
        cpuCacheMode = texture.cpuCacheMode
        storageMode = texture.storageMode
        hazardTrackingMode = texture.hazardTrackingMode
        usage = texture.usage
        allowGPUOptimizedContents = texture.allowGPUOptimizedContents
        compressionType = texture.compressionType
        swizzle = texture.swizzle
    }
}
