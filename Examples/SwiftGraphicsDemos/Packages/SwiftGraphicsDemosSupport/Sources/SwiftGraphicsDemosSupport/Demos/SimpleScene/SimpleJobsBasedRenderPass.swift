import Metal
import RenderKit

final class SimpleJobsBasedRenderPass: RenderPass {
    var jobs: [any RenderJob]

    init(jobs: [any RenderJob]) {
        self.jobs = jobs
    }

    func setup(device: MTLDevice, configuration: inout some MetalConfiguration) throws {
        try jobs.forEach { job in
            try job.setup(device: device, configuration: &configuration)
        }
    }

    func drawableSizeWillChange(device: MTLDevice, size: CGSize) throws {
        try jobs.forEach { job in
            try job.drawableSizeWillChange(device: device, size: size)
        }
    }

    func draw(device: MTLDevice, size: CGSize, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) throws {
        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor) { encoder in
            encoder.label = "SimpleJobsBasedRenderPass-RenderCommandEncoder"
            try jobs.forEach { job in
                try job.encode(on: encoder, size: size)
            }
        }
    }
}

extension SimpleJobsBasedRenderPass: Observable {
}
