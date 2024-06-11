import Algorithms
import Metal
import MetalKit
import Shapes3D
import SwiftGraphicsSupport

extension SimpleScene {
    static func demo(device: MTLDevice) throws -> SimpleScene {
        let allocator = MTKMeshBufferAllocator(device: device)
        let cone = try Cone3D(height: 1, radius: 0.5).toYAMesh(allocator: allocator, device: device)
        let sphere = try Sphere3D(radius: 0.25).toYAMesh(allocator: allocator, device: device)
        let capsule = try Capsule3D(height: 1, radius: 0.05).toYAMesh(allocator: allocator, device: device)

        let meshes = [cone, sphere, capsule]

        let xRange = [Float](stride(from: -2, through: 2, by: 1))
        let zRange = [Float](stride(from: 0, through: -10, by: -1))
//        let xRange = [Float](stride(from: 0, through: 0, by: 1))
//        let zRange = [Float](stride(from: 1, through: 1, by: -1))

        let tilesSize: SIMD2<UInt16>
        let tileTextures: [(MTKTextureLoader) throws -> MTLTexture]
        tilesSize = [1, 1]
        // swiftlint:disable:next multiline_literal_brackets opening_brace
        tileTextures = [{ loader in
            try loader.newTexture(name: "BlueSkySkybox", scaleFactor: 1, bundle: .module, options: [
                .textureStorageMode: MTLStorageMode.private.rawValue,
                .SRGB: true,
            ])
            },
        ]

        var models: [Model] = []
        models += product(xRange, zRange).map { x, z in
            let hsv: SIMD3<Float> = [Float.random(in: 0 ... 1), 1, 1]
            let rgba = SIMD4<Float>(hsv.hsv2rgb(), 1.0)
            let material = FlatMaterial(baseColorFactor: rgba, baseColorTexture: .init(resource: BundleResourceReference(bundle: .bundle(.module), name: "Checkerboard")))
            return Model(transform: .translation([x, 0, z]), material: material, mesh: meshes.randomElement()!)
        }

        let fishModel = try Model(
            transform: .translation([0, 1, 0]).rotated(angle: .degrees(90), axis: [0, 1, 0]),
            material: UnlitMaterial(baseColorFactor: [1, 0, 1, 1], baseColorTexture: .init(resource: BundleResourceReference(bundle: .bundle(.module), name: "seamless-foods-mixed-0020"))),
            mesh: YAMesh(gltf: "Models/BarramundiFish", in: Bundle.module, device: device)
        )
        models.append(fishModel)

        let panorama = Panorama(tilesSize: tilesSize, tileTextures: tileTextures) { device in
            let allocator = MTKMeshBufferAllocator(device: device)
            return try YAMesh(mdlMesh: try Sphere3D(radius: 47.5).toMDLMesh(allocator: allocator), device: device)
        }

        let scene = SimpleScene(
            camera: LegacyCamera(transform: .translation([0, 0, 2]), target: [0, 0, -1], projection: .perspective(.init(fovy: .degrees(90), zClip: 0.1 ... 100))),
            light: .init(position: .translation([-2, 2, -1]), color: [1, 1, 1], power: 1),
            ambientLightColor: [0, 0, 0],
            models: models,
            panorama: panorama
        )

        return scene
    }
}
