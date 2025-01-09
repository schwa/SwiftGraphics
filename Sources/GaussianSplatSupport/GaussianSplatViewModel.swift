import BaseSupport
@preconcurrency import Metal
#if !targetEnvironment(simulator)
import MetalFX
#endif
import Widgets3D
import MetalKit
import MetalSupport
import ModelIO
import os
import RenderKit
import RenderKitSceneGraph
import Shapes3D
import simd
import SIMDSupport
import SwiftUI
import Traces

@Observable
@MainActor
public class GaussianSplatViewModel {
    public typealias Splat = SplatC

    @ObservationIgnored
    private let device: MTLDevice

    public var configuration: GaussianSplatConfiguration

    public var scene: SceneGraph {
        didSet {
            if oldValue.currentCameraNode?.transform != scene.currentCameraNode?.transform {
                cameraChanged()
            }
            try? updatePass()
        }
    }

    public var pass: GroupPass?

    public var loadProgress = Progress()

    public var splatCloud: SplatCloud<SplatC> {
        get {
            scene.firstSplatCloud!
        }
        set {
            try! scene.modify(label: "splats") { node in
                node!.content = newValue
            }
        }
    }

    @ObservationIgnored
    public var frame: Int = 0 {
        didSet {
            try! updatePass()
        }
    }

    @ObservationIgnored
    private var resources: GaussianSplatResources?

    @ObservationIgnored
    private var logger: Logger?

    @ObservationIgnored
    private var cpuSorter: AsyncSortManager<Splat>?

    @ObservationIgnored
    private var cpuSorterTask: Task<Void, Never>?

    // MARK: -

    public init(device: MTLDevice, splatCloud: SplatCloud<SplatC>, configuration: GaussianSplatConfiguration, logger: Logger? = nil) throws {
        self.device = device
        self.configuration = configuration
        self.logger = logger

        let root = Node(label: "root") {
            Node(label: "camera", content: Camera(projection: .perspective(.init(verticalAngleOfView: configuration.verticalAngleOfView, zClip: 0.001...250))))
            //            if let skyboxTexture = configuration.skyboxTexture {
            //                try Node.skybox(device: device, texture: skyboxTexture)
            //                let panoramaMDLMesh = MDLMesh(sphereWithExtent: [200, 200, 200], segments: [36, 36], inwardNormals: true, geometryType: .triangles, allocator: allocator)
            //                let panoramaMTKMesh = try! MTKMesh(mesh: panoramaMDLMesh, device: device)
            //                Node(label: "skyBox", content: Geometry(mesh: panoramaMTKMesh, materials: [PanoramaMaterial(baseColorTexture: skyboxTexture)]))
            //            }
            Node(label: "splats", content: splatCloud).transformed(roll: .zero, pitch: .degrees(270), yaw: .zero).transformed(roll: .zero, pitch: .zero, yaw: .degrees(90))
        }
        self.scene = SceneGraph(root: root)
        loadProgress.completedUnitCount = Int64(splatCloud.count)
        loadProgress.totalUnitCount = Int64(splatCloud.count)

        let cpuSorter = try AsyncSortManager<Splat>(device: device, splatCloud: splatCloud, capacity: splatCloud.capacity)
        let cpuSorterTask = Task {
            for await splatIndices in await cpuSorter.sortedIndicesChannel().buffer(policy: .bufferingLatest(1)) {
                Traces.shared.trace(name: "Sorted Splats")
                splatCloud.indexedDistances = splatIndices
                try? updatePass()
            }
        }
        self.cpuSorter = cpuSorter
        self.cpuSorterTask = cpuSorterTask
        try updatePass()
    }

    // MARK: -

    internal func cameraChanged() {
        Traces.shared.trace(name: "Camera Changed")
        requestSort()
    }

    internal func updatePass() throws {
        guard let resources, let cameraNode = scene.currentCameraNode, let splatsNode = scene.firstSplatsNode, let splats = scene.firstSplatCloud else {
            logger?.log("Missing dependencies")
            return
        }

        let fullRedraw = true
        self.pass = try GroupPass(id: "FullPass") {
            if fullRedraw {
                GroupPass(id: "g1") {
                    let sortEnabled = configuration.sortMethod == .gpuBitonic && (frame <= 1 || frame.isMultiple(of: 15))
                    if configuration.sortMethod == .gpuBitonic && sortEnabled {
                        GaussianSplatDistanceComputePass(
                            id: "distance-compute",
                            splats: splats,
                            modelMatrix: simd_float3x3(truncating: splatsNode.transform.matrix),
                            cameraPosition: cameraNode.transform.matrix.translation
                        )
                         GaussianSplatBitonicSortComputePass(id: "sort", splats: splats)
                    }
                    if configuration.renderSkybox && fullRedraw {
                        GroupPass(id: "g2", renderPassDescriptor: initialRenderPassDescriptor) {
                            PanoramaShadingPass(id: "pano", scene: scene)
                        }
                    }
                    if configuration.renderSplats && fullRedraw {
                        GroupPass(id: "g3", renderPassDescriptor: secondaryRenderPassDescriptor) {
                            GaussianSplatRenderPass<Splat>(id: "gaussian-render", scene: scene, discardRate: configuration.discardRate)
                        }
                    }
                }
            }
            #if !targetEnvironment(simulator)
            if configuration.metalFXRate > 1 && fullRedraw {
                try SpatialUpscalingPass(id: "SpatialUpscalingPass", device: device, source: resources.downscaledTexture, destination: resources.outputTexture, colorProcessingMode: .perceptual)
            }
            let blitTexture = resources.outputTexture
            #else
            let blitTexture = resources.downscaledTexture
            #endif
            BlitTexturePass(id: "blit", source: blitTexture, destination: nil)
        }
    }

    public func drawableChanged(pixelFormat: MTLPixelFormat, size: SIMD2<Float>) throws {
        try makeResources(pixelFormat: pixelFormat, size: size)
    }

    // MARK: -

    private func makeResources(pixelFormat: MTLPixelFormat, size: SIMD2<Float>) throws {
        #if !targetEnvironment(simulator)
        let downscaledSize = SIMD2<Int>(ceil(size / configuration.metalFXRate))
        #else
        let downscaledSize = SIMD2<Int>(size)
        #endif
        let colorTexture = try device.makeTexture(pixelFormat: pixelFormat, size: downscaledSize, usage: [.renderTarget, .shaderRead], label: "reduce-resolution-color-\(size)")
        let depthTexture = try device.makeTexture(pixelFormat: .depth32Float, size: downscaledSize, usage: [.renderTarget, .shaderRead], label: "reduce-resolution-depth-\(size)")
        let upscaledTexture = try device.makeTexture(pixelFormat: pixelFormat, size: SIMD2<Int>(size), usage: [.renderTarget], label: "reduce-resolution-upscaled-\(size)")

        self.resources = .init(downscaledTexture: colorTexture, downscaledDepthTexture: depthTexture, outputTexture: upscaledTexture)
    }

    private var initialRenderPassDescriptor: MTLRenderPassDescriptor {
        guard let resources else {
            fatalError("Tried to create renderpass without resources.")
        }
        let offscreenRenderPassDescriptor = MTLRenderPassDescriptor()
        offscreenRenderPassDescriptor.colorAttachments[0].clearColor = configuration.clearColor
        offscreenRenderPassDescriptor.colorAttachments[0].texture = configuration.metalFXRate <= 1 ? resources.outputTexture : resources.downscaledTexture
        offscreenRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        offscreenRenderPassDescriptor.colorAttachments[0].storeAction = .store
        offscreenRenderPassDescriptor.depthAttachment.loadAction = .clear
        offscreenRenderPassDescriptor.depthAttachment.storeAction = .store
        offscreenRenderPassDescriptor.depthAttachment.clearDepth = 1.0
        offscreenRenderPassDescriptor.depthAttachment.texture = resources.downscaledDepthTexture
        return offscreenRenderPassDescriptor
    }

    private var secondaryRenderPassDescriptor: MTLRenderPassDescriptor {
        guard let resources else {
            fatalError("Tried to create renderpass without resources.")
        }
        let offscreenRenderPassDescriptor = MTLRenderPassDescriptor()
        offscreenRenderPassDescriptor.colorAttachments[0].texture = configuration.metalFXRate <= 1 ? resources.outputTexture : resources.downscaledTexture
        offscreenRenderPassDescriptor.colorAttachments[0].loadAction = .load
        offscreenRenderPassDescriptor.colorAttachments[0].storeAction = .store
        offscreenRenderPassDescriptor.depthAttachment.loadAction = .clear
        offscreenRenderPassDescriptor.depthAttachment.storeAction = .dontCare
        offscreenRenderPassDescriptor.depthAttachment.clearDepth = 1.0
        offscreenRenderPassDescriptor.depthAttachment.texture = resources.downscaledDepthTexture
        return offscreenRenderPassDescriptor
    }

    public func requestSort() {
        guard configuration.sortMethod == .cpuRadix, let cpuSorter else {
            return
        }
        guard let splatsNode = scene.firstSplatsNode, let splatCloud = scene.firstSplatCloud, let cameraNode = scene.currentCameraNode else {
            logger?.log("Can't sort. Missing dependencies.")
            return
        }
        cpuSorter.requestSort(camera: cameraNode.transform.matrix, model: splatsNode.transform.matrix, count: splatCloud.splats.count)
        Traces.shared.trace(name: "Sort Requested")
    }
}

// MARK: -

struct GaussianSplatResources {
    var downscaledTexture: MTLTexture
    var downscaledDepthTexture: MTLTexture
    var outputTexture: MTLTexture
}

// MARK: -

@available(iOS 17, macOS 14, visionOS 1, *)
public extension GaussianSplatViewModel {
    convenience init(device: MTLDevice, splatCapacity: Int, configuration: GaussianSplatConfiguration, logger: Logger? = nil) throws {
        try self.init(device: device, splatCloud: SplatCloud<SplatC>(device: device, capacity: splatCapacity), configuration: configuration, logger: logger)
    }
}

public extension SceneGraph {
    var firstSplatsNode: Node? {
        guard let splatsNode = firstNode(label: "splats") else {
            return nil
        }
        return splatsNode
    }

    var firstSplatCloud: SplatCloud<SplatC>? {
        guard let splatsNode = firstSplatsNode, let splatCloud = splatsNode.content as? SplatCloud<SplatC> else {
            return nil
        }
        return splatCloud
    }
}
