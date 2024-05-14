import Metal
import MetalKit
import ModelIO
import Observation
import RenderKit
import RenderKitShaders
import SIMDSupport
import SwiftUI

protocol SceneRenderJob: RenderJob {
    var scene: SimpleScene { get set }
    var textureManager: TextureManager { get set }
}

class SimpleSceneRenderPass: RenderPass {
    var scene: SimpleScene {
        didSet {
            for job in renderJobs {
                job.scene = scene
            }
        }
    }

    var renderJobs: [any RenderJob & SceneRenderJob] = []

    var textureManager: TextureManager?

    init(scene: SimpleScene) {
        self.scene = scene
    }

    func setup(device: MTLDevice, configuration: inout some MetalConfiguration) throws {
        let textureManager = TextureManager(device: device)
        self.textureManager = textureManager

        if let panorama = scene.panorama {
            let job = PanoramaRenderJob(scene: scene, textureManager: textureManager, panorama: panorama)
            job.scene = scene
            renderJobs.append(job)
        }

        let flatModels = scene.models.filter { ($0.material as? FlatMaterial) != nil }
        if !flatModels.isEmpty {
            let job = FlatMaterialRenderJob(scene: scene, textureManager: textureManager, models: flatModels)
            renderJobs.append(job)
        }

        let unlitModels = scene.models.filter { ($0.material as? UnlitMaterial) != nil }
        if !unlitModels.isEmpty {
            let job = UnlitMaterialRenderJob(scene: scene, textureManager: textureManager, models: unlitModels)
            renderJobs.append(job)
        }

        try renderJobs.forEach { job in
            try job.setup(device: device, configuration: &configuration)
        }
    }

    func draw(device: MTLDevice, size: CGSize, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) throws {
        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor) { encoder in
            encoder.label = "SimpleJobsBasedRenderPass-RenderCommandEncoder"
            try renderJobs.forEach { job in
                try job.encode(on: encoder, size: size)
            }
        }
    }
}

// MARK: -
