import BaseSupport
import GaussianSplatShaders
@preconcurrency import Metal
import MetalSupport
import RenderKit
import simd

public struct GaussianSplatBitonicSortComputePass <Splat>: ComputePassProtocol where Splat: SplatProtocol {
    public struct State: Sendable {
        var pipelineState: MTLComputePipelineState
        var bindings: Bindings
    }

    typealias Bindings = GaussianSplatBitonicSortComputePassBindings

    public var id: PassID
    var splats: SplatCloud<Splat>

    public init(id: PassID, splats: SplatCloud<Splat>) {
        self.id = id
        self.splats = splats
    }

    public func setup(device: MTLDevice) throws -> State {
        guard let bundle = Bundle.main.bundle(forTarget: "GaussianSplatShaders") else {
            throw BaseError.error(.missingResource)
        }
        let library = try device.makeDebugLibrary(bundle: bundle)
        let function = library.makeFunction(name: "GaussianSplatShaders::BitonicSortSplats").forceUnwrap("No function found")
        let (pipelineState, reflection) = try device.makeComputePipelineState(function: function, options: .bindingInfo)

        var bindings = Bindings()
        try bindings.updateBindings(with: reflection)

        return State(
            pipelineState: pipelineState,
            bindings: bindings
        )
    }

    public func compute(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws {
        guard splats.splats.count >= 2 else {
            return
        }
        let computePipelineState = state.pipelineState
        let computePassDescriptor = MTLComputePassDescriptor()
        info.gpuCounters?.updateComputePassDescriptor(computePassDescriptor)
        let commandEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor).forceUnwrap()
        commandEncoder.label = "GaussianSplatBitonicSortComputePass"
        commandEncoder.withDebugGroup("GaussianSplatBitonicSortComputePass") {
            commandEncoder.setComputePipelineState(computePipelineState)
            commandEncoder.setBuffer(splats.indexedDistances.indices, offset: 0, index: state.bindings.indexedDistances)
            let splatCount = splats.splats.count
            let numStages = Int(log2(nextPowerOfTwo(Double(splatCount))))
            var threadgroupsPerGrid = (splatCount + computePipelineState.maxTotalThreadsPerThreadgroup - 1) / computePipelineState.maxTotalThreadsPerThreadgroup
            threadgroupsPerGrid = (threadgroupsPerGrid + computePipelineState.threadExecutionWidth - 1) / computePipelineState.threadExecutionWidth * computePipelineState.threadExecutionWidth
            for stageIndex in 0 ..< numStages {
                commandEncoder.withDebugGroup("Stage \(stageIndex) of \(numStages)") {
                    for stepIndex in 0 ..< (stageIndex + 1) {
                        let groupWidth = 1 << (stageIndex - stepIndex)
                        let groupHeight = 2 * groupWidth - 1

                        // TODO: Changing all the uniforms per call() is a bit over the top but hey.
                        let uniforms = GaussianSplatSortUniforms(splatCount: UInt32(splatCount), groupWidth: UInt32(groupWidth), groupHeight: UInt32(groupHeight), stepIndex: UInt32(stepIndex))
                        commandEncoder.setBytes(of: uniforms, index: state.bindings.uniforms)
                        commandEncoder.dispatchThreadgroups(MTLSize(width: threadgroupsPerGrid), threadsPerThreadgroup: MTLSize(width: computePipelineState.maxTotalThreadsPerThreadgroup))
                    }
                }
            }
        }
        commandEncoder.endEncoding()
    }
}

@MetalBindings
struct GaussianSplatBitonicSortComputePassBindings {
    var uniforms: Int = -1
    var indexedDistances: Int = -1
}
