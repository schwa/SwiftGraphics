import RenderKit
import Metal

public final class SimpleJobsBasedRenderPass: RenderPass {
    public var jobs: [any RenderJob]

    public init(jobs: [any RenderJob]) {
        self.jobs = jobs
    }

    public func setup<Configuration: MetalConfiguration>(device: MTLDevice, configuration: inout Configuration) throws {
        try jobs.forEach { job in
            try job.setup(device: device, configuration: &configuration)
        }
    }

    public func drawableSizeWillChange(device: MTLDevice, size: CGSize) throws {
        try jobs.forEach { job in
            try job.drawableSizeWillChange(device: device, size: size)
        }
    }

    public func draw(device: MTLDevice, size: CGSize, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) throws {
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
