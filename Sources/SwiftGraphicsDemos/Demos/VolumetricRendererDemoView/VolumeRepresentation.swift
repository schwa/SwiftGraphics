import BaseSupport
import Metal
import RenderKitShadersLegacy
import Shapes2D

struct VolumeRepresentation: @unchecked Sendable {
    var volumeData: VolumeData

    var transferFunctionTexture: MTLTexture
    var texture: MTLTexture
    var mesh: YAMesh
    var instanceCount: Int
    var instanceBuffer: MTLBuffer

    init(device: MTLDevice, volumeData: VolumeData) throws {
        //        let volumeData = try VolumeData(named: "CThead", in: Bundle.module, size: [256, 256, 113]) // TODO: Hardcoded
        let load = try volumeData.load()
        texture = try load(device)

        // TODO: Hardcoded
        let textureDescriptor = MTLTextureDescriptor()
        // We actually only need this texture to be 1D but Metal doesn't allow buffer backed 1D textures which seems assinine. Maybe we don't need it to be buffer backed and just need to call texture.copy each update?
        textureDescriptor.textureType = .type1D
        textureDescriptor.width = 256 // TODO: Hardcoded
        textureDescriptor.height = 1
        textureDescriptor.depth = 1
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.storageMode = .shared
        let texture = try device.makeTexture(descriptor: textureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        texture.label = "transfer function"
        self.transferFunctionTexture = texture

        let rect = CGRect(center: .zero, radius: 0.5)
        let circle = Shapes2D.Circle(containing: rect)
        let triangle = Triangle(containing: circle)
        mesh = try YAMesh.triangle(label: "triangle", triangle: triangle, device: device) {
            SIMD2<Float>($0) + [0.5, 0.5]
        }

        let instanceCount = 256 // TODO: Random - numbers as low as 32 - but you will see layering in the image.
        let instances = (0 ..< instanceCount).map { slice in
            let z = Float(slice) / Float(instanceCount - 1)
            return VolumeInstance(offsetZ: z - 0.5, textureZ: 1 - z)
        }
        self.instanceBuffer = try device.makeBuffer(bytesOf: instances, options: .storageModeShared)
        self.instanceBuffer.label = "instances"
        assert(self.instanceBuffer.length == 8 * instanceCount)
        self.instanceCount = instanceCount
        self.volumeData = volumeData
    }
}
