import BaseSupport
import Metal
#if !targetEnvironment(simulator)
import MetalFX
#endif
import MetalKit
import MetalSupport
import os
import RenderKit
import RenderKitSceneGraph
import Shapes3D
import simd
import SIMDSupport
import SwiftUI
import SwiftUISupport

@Observable
@MainActor
public class GaussianSplatViewModel <Splat> where Splat: SplatProtocol {
    @ObservationIgnored
    public let device: MTLDevice

    @ObservationIgnored
    public var configuration: GaussianSplatRenderingConfiguration

    @ObservationIgnored
    private var resources: GaussianSplatResources?

    @ObservationIgnored
    public var frame: Int = 0 {
        didSet {
            try! sceneChanged()
        }
    }

    public var scene: SceneGraph {
        didSet {

            if oldValue.currentCameraNode?.transform != scene.currentCameraNode?.transform {
                cameraChanged()
            }

            try! sceneChanged()
        }
    }

    public var pass: GroupPass?

    public var loadProgress = Progress()

    @ObservationIgnored
    private var logger: Logger?

    // TODO: bang and try!
    public var splatCloud: SplatCloud<SplatC> {
        get {
            scene.firstNode(label: "splats")!.content as! SplatCloud<SplatC>
        }
        set {
            try! scene.modify(label: "splats") { node in
                node!.content = newValue
            }
        }
    }

    public init(device: MTLDevice, splatCloud: SplatCloud<SplatC>, configuration: GaussianSplatRenderingConfiguration = .init(), logger: Logger? = nil) throws {
        self.device = device
        self.configuration = configuration
        self.logger = logger

        let panoramaMesh = try Box3D(min: [-400, -400, -400], max: [400, 400, 400]).toMTKMesh(device: device, inwardNormals: true)
        let loader = MTKTextureLoader(device: device)
        let panoramaTexture = try loader.newTexture(name: "Grid", scaleFactor: 2, bundle: Bundle.module)
        let root = Node(label: "root") {
            Node(label: "camera", content: Camera())
            Node(label: "pano", content: Geometry(mesh: panoramaMesh, materials: [PanoramaMaterial(baseColorTexture: panoramaTexture)]))
            Node(label: "splats", content: splatCloud).transformed(roll: .zero, pitch: .degrees(270), yaw: .zero).transformed(roll: .zero, pitch: .zero, yaw: .degrees(90)).transformed(translation: [0, 0.25, 0.5])
        }
        self.scene = SceneGraph(root: root)
        try sceneChanged()
        loadProgress.completedUnitCount = Int64(splatCloud.count)
        loadProgress.totalUnitCount = Int64(splatCloud.count)
    }

    var isSorting = false

    func cameraChanged() {
        sort()
        }



    func sceneChanged() throws {
        guard let resources else {
            logger?.log("Missing resources")
            return
        }
        guard let splatsNode = scene.firstNode(label: "splats"), let splats = splatsNode.content as? SplatCloud<Splat> else {
            logger?.log("Missing splats")
            return
        }
        guard let cameraNode = scene.firstNode(label: "camera") else {
            logger?.log("Missing camera")
            return
        }

        let fullRedraw = true
        //        let sortEnabled = (frame <= 1 || frame.isMultiple(of: configuration.sortRate))

//        if sortEnabled {
//            try scene.modify(label: "splats") { node in
//                var splats = node!.content as! SplatCloud<Splat>
//                splats.sortIndices(camera: cameraNode.transform.matrix)
//                node!.content = splats
//            }
//        }

        self.pass = try GroupPass(id: "FullPass") {
            GroupPass(id: "GaussianSplatRenderGroup", enabled: fullRedraw, renderPassDescriptor: offscreenRenderPassDescriptor) {
//                GaussianSplatDistanceComputePass(
//                    id: "SplatDistanceCompute",
//                    enabled: sortEnabled,
//                    splats: splats,
//                    modelMatrix: simd_float3x3(truncating: splatsNode.transform.matrix),
//                    cameraPosition: cameraNode.transform.translation
//                )
//                GaussianSplatBitonicSortComputePass(
//                    id: "SplatBitonicSort",
//                    enabled: sortEnabled,
//                    splats: splats
//                )
                PanoramaShadingPass(id: "Panorama", scene: scene)
                GaussianSplatRenderPass<Splat>(
                    id: "SplatRender",
                    enabled: true,
                    scene: scene,
                    discardRate: configuration.discardRate
                )
            }
            #if !targetEnvironment(simulator)
            try SpatialUpscalingPass(id: "SpatialUpscalingPass", enabled: configuration.metalFXRate > 1 && fullRedraw, device: device, source: resources.downscaledTexture, destination: resources.outputTexture, colorProcessingMode: .perceptual)
            #endif
            BlitTexturePass(id: "BlitTexturePass", source: resources.outputTexture, destination: nil)
        }
    }

    func makeResources(pixelFormat: MTLPixelFormat, size: SIMD2<Float>) throws {
        logger?.debug("makeMetalFXTextures - \(size) \(self.configuration.metalFXRate)")
        let downscaledSize = SIMD2<Int>(ceil(size / configuration.metalFXRate))

        let colorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: downscaledSize.x, height: downscaledSize.y, mipmapped: false)
        colorTextureDescriptor.storageMode = .private
        colorTextureDescriptor.usage = [.renderTarget, .shaderRead]
        let colorTexture = try device.makeTexture(descriptor: colorTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        colorTexture.label = "reduce-resolution-color-\(colorTexture.size.shortDescription)"

        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: downscaledSize.x, height: downscaledSize.y, mipmapped: false)
        depthTextureDescriptor.storageMode = .private
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead]
        let depthTexture = try device.makeTexture(descriptor: depthTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        depthTexture.label = "reduce-resolution-depth-\(depthTexture.size.shortDescription)"

        let upscaledTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: Int(ceil(size.x)), height: Int(ceil(size.y)), mipmapped: false)
        upscaledTextureDescriptor.storageMode = .private
        upscaledTextureDescriptor.usage = .renderTarget
        let upscaledTexture = try device.makeTexture(descriptor: upscaledTextureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
        upscaledTexture.label = "reduce-resolution-upscaled-\(upscaledTexture.size.shortDescription)"

        self.resources = .init(downscaledTexture: colorTexture, downscaledDepthTexture: depthTexture, outputTexture: upscaledTexture)
    }

    var offscreenRenderPassDescriptor: MTLRenderPassDescriptor {
        guard let resources else {
            fatalError("Tried to create renderpass without resources.")
        }
        let offscreenRenderPassDescriptor = MTLRenderPassDescriptor()
        offscreenRenderPassDescriptor.colorAttachments[0].clearColor = configuration.clearColor
        offscreenRenderPassDescriptor.colorAttachments[0].texture = configuration.metalFXRate <= 1 ? resources.outputTexture : resources.downscaledTexture
        offscreenRenderPassDescriptor.colorAttachments[0].loadAction = .load
        offscreenRenderPassDescriptor.colorAttachments[0].storeAction = .store
        offscreenRenderPassDescriptor.depthAttachment.loadAction = .clear
        offscreenRenderPassDescriptor.depthAttachment.storeAction = .dontCare
        offscreenRenderPassDescriptor.depthAttachment.clearDepth = 1.0
        offscreenRenderPassDescriptor.depthAttachment.texture = resources.downscaledDepthTexture
        return offscreenRenderPassDescriptor
    }

    func sort() {
        guard isSorting == false else {
            return
        }
        guard let splatsNode = scene.firstNode(label: "splats"), let splatCloud = splatsNode.content as? SplatCloud<Splat> else {
            logger?.log("Missing splats")
            return
        }
        guard let cameraNode = scene.firstNode(label: "camera") else {
            logger?.log("Missing camera")
            return
        }
        isSorting = true
        Task.detached {
            print("SORT STARTED")
            splatCloud.sortIndices(camera: cameraNode.transform.matrix, model: splatsNode.transform.matrix)
            await MainActor.run {
                splatCloud.indexedDistances.rotate()
                print("SORT ENDED")
                self.isSorting = false
            }
        }
    }
}

// MARK: -

struct GaussianSplatResources {
    var downscaledTexture: MTLTexture
    var downscaledDepthTexture: MTLTexture
    var outputTexture: MTLTexture
}

extension MTLSize {
    var shortDescription: String {
        depth == 1 ? "\(width)x\(height)" : "\(width)x\(height)x\(depth)"
    }
}

// MARK: -

public extension GaussianSplatViewModel where Splat == SplatC {
    convenience init(device: MTLDevice, splatCount: Int, configuration: GaussianSplatRenderingConfiguration = .init(), logger: Logger? = nil) throws {
        try self.init(device: device, splatCloud: SplatCloud<SplatC>(device: device), configuration: configuration, logger: logger)
    }

    func streamingLoad(url: URL) async throws {
        assert(MemoryLayout<SplatB>.stride == MemoryLayout<SplatB>.size)

        let session = URLSession.shared

        // Perform a HEAD request to compute the number of splats.
        var headRequest = URLRequest(url: url)
        headRequest.httpMethod = "HEAD"
        let (_, headResponse) = try await session.data(for: headRequest)
        guard let headResponse = headResponse as? HTTPURLResponse else {
            fatalError("Oops")
        }
        guard headResponse.statusCode == 200 else {
            throw BaseError.missingResource
        }
        guard let contentLength = try (headResponse.allHeaderFields["Content-Length"] as? String).map(Int.init)?.safelyUnwrap(BaseError.optionalUnwrapFailure) else {
            fatalError("Oops")
        }
        guard contentLength.isMultiple(of: MemoryLayout<SplatB>.stride) else {
            fatalError("Not an even multiple of \(MemoryLayout<SplatB>.stride)")
        }
        let splatCount = contentLength / MemoryLayout<SplatB>.stride
        print("Content length: \(contentLength), splat count: \(splatCount)")

        loadProgress.totalUnitCount = Int64(splatCount)

        // Start loading splats into a new splat cloud with the right capacity...
        splatCloud = try SplatCloud<Splat>(device: device, capacity: splatCount)
        let request = URLRequest(url: url)
        let (byteStream, bytesResponse) = try await session.bytes(for: request)
        guard let bytesResponse = bytesResponse as? HTTPURLResponse else {
            fatalError("Oops")
        }
        guard bytesResponse.statusCode == 200 else {
            throw BaseError.missingResource
        }
        let splatStream = byteStream.chunks(ofCount: MemoryLayout<SplatB>.stride).map { bytes in
            bytes.withUnsafeBytes { buffer in
                let splatB = buffer.load(as: SplatB.self)
                return SplatC(splatB)
            }
        }
        .chunks(ofCount: 2048)

        for try await splats in splatStream {
            try splatCloud.append(splats: splats)
            self.sort()
            loadProgress.completedUnitCount = Int64(splatCloud.count)

        }
        assert(splatCloud.count == splatCount)

//        let data = try Data(contentsOf: url)
//        print(data.count, contentLength)
//        let splats = try SplatCloud<SplatC>(device: device, data: data)
//        print(splats.count == splatCloud.count)
//        print(splats.count, splatCloud.count)
//        print(Data(splats.splats.unsafeBase!.contentsBuffer()) == Data(splatCloud.splats.unsafeBase!.contentsBuffer()))
//        print(splats.splats.unsafeBase!.length, splatCloud.splats.unsafeBase!.length)
    }
}
