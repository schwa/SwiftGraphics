import BaseSupport
import Metal
#if !targetEnvironment(simulator)
import MetalFX
#endif
import Constraints3D
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

public struct GaussianSplatConfiguration {
    public var bounds: ConeBounds
    public var debugMode: Bool
    public var metalFXRate: Float
    public var discardRate: Float
    public var gpuCounters: GPUCounters?
    public var clearColor: MTLClearColor // TODO: make this a SwiftUI Color
    public var verticalAngleOfView: Angle
    public var useGPUSort: Bool

    public init(bounds: ConeBounds, debugMode: Bool = false, metalFXRate: Float = 2, discardRate: Float = 0.0, gpuCounters: GPUCounters? = nil, clearColor: MTLClearColor = .init(red: 0, green: 0, blue: 0, alpha: 1), verticalAngleOfView: Angle = .degrees(90), useGPUSort: Bool = false) {
        self.debugMode = debugMode
        self.metalFXRate = metalFXRate
        self.discardRate = discardRate
        self.gpuCounters = gpuCounters
        self.clearColor = clearColor
        self.verticalAngleOfView = verticalAngleOfView
        self.useGPUSort = useGPUSort
        self.bounds = bounds
    }
}

@Observable
@MainActor
public class GaussianSplatViewModel <Splat> where Splat: SplatProtocol {
    @ObservationIgnored
    public let device: MTLDevice

    @ObservationIgnored
    public var configuration: GaussianSplatConfiguration

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

    public var splatResource: SplatResource

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

    public init(device: MTLDevice, splatResource: SplatResource, splatCloud: SplatCloud<SplatC>, configuration: GaussianSplatConfiguration, logger: Logger? = nil) throws {
        self.device = device
        self.splatResource = splatResource
        self.configuration = configuration
        self.logger = logger

        let panoramaMesh = try Box3D(min: [-400, -400, -400], max: [400, 400, 400]).toMTKMesh(device: device, inwardNormals: true)
        let loader = MTKTextureLoader(device: device)
        let panoramaTexture = try loader.newTexture(name: "Grid", scaleFactor: 2, bundle: Bundle.module)
        let root = Node(label: "root") {
            Node(label: "camera", content: Camera(projection: .perspective(.init(verticalAngleOfView: configuration.verticalAngleOfView))))
            Node(label: "pano", content: Geometry(mesh: panoramaMesh, materials: [PanoramaMaterial(baseColorTexture: panoramaTexture)]))
            Node(label: "splats", content: splatCloud).transformed(roll: .zero, pitch: .degrees(270), yaw: .zero).transformed(roll: .zero, pitch: .zero, yaw: .degrees(90))
        }
        self.scene = SceneGraph(root: root)
        try sceneChanged()
        loadProgress.completedUnitCount = Int64(splatCloud.count)
        loadProgress.totalUnitCount = Int64(splatCloud.count)
    }

    var isSorting = false

    internal func cameraChanged() {
        sort()
    }

    internal func sceneChanged() throws {
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
        let sortEnabled = (frame <= 1 || frame.isMultiple(of: 15))

        self.pass = try GroupPass(id: "FullPass") {
            GroupPass(id: "GaussianSplatRenderGroup", enabled: fullRedraw, renderPassDescriptor: offscreenRenderPassDescriptor) {
                if configuration.useGPUSort {
                    GaussianSplatDistanceComputePass(
                        id: "SplatDistanceCompute",
                        enabled: sortEnabled,
                        splats: splats,
                        modelMatrix: simd_float3x3(truncating: splatsNode.transform.matrix),
                        cameraPosition: cameraNode.transform.translation
                    )
                    GaussianSplatBitonicSortComputePass(
                        id: "SplatBitonicSort",
                        enabled: sortEnabled,
                        splats: splats
                    )
                }
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

    public func drawableChanged(pixelFormat: MTLPixelFormat, size: SIMD2<Float>) throws {
        print("###################", #function, pixelFormat, size)
        try makeResources(pixelFormat: pixelFormat, size: size)
    }

    // MARK: -

    private func makeResources(pixelFormat: MTLPixelFormat, size: SIMD2<Float>) throws {
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

    private var offscreenRenderPassDescriptor: MTLRenderPassDescriptor {
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

    private func sort() {
        guard configuration.useGPUSort == false else {
            return
        }
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
    convenience init(device: MTLDevice, splatResource: SplatResource, splatCount: Int, configuration: GaussianSplatConfiguration, logger: Logger? = nil) throws {
        try self.init(device: device, splatResource: splatResource, splatCloud: SplatCloud<SplatC>(device: device), configuration: configuration, logger: logger)
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
    }
}
