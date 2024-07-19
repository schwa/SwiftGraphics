import BaseSupport
import GaussianSplatShaders
@preconcurrency import Metal
import MetalSupport
import RenderKit
import simd

public struct GaussianSplatBitonicSortComputePass: ComputePassProtocol {
    public struct State: PassState {
        var pipelineState: MTLComputePipelineState
        var bindingsUniformsIndex: Int
        var bindingsSplatDistancesIndex: Int
        var bindingsSplatIndicesIndex: Int
        var frameCount: Int = 0
    }

    public var id = PassID("GaussianSplatBitonicSortComputePass")
    var splats: SplatCloud
    var sortRate: Int

    public init(splats: SplatCloud, sortRate: Int) {
        self.splats = splats
        self.sortRate = sortRate
    }

    public func setup(device: MTLDevice) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .gaussianSplatShaders)
        let function = library.makeFunction(name: "GaussianSplatShaders::BitonicSortSplats").forceUnwrap("No function found")
        let (pipelineState, reflection) = try device.makeComputePipelineState(function: function, options: .bindingInfo)
        guard let reflection else {
            fatalError("Failed to create pipeline state.")
        }
        return State(
            pipelineState: pipelineState,
            bindingsUniformsIndex: try reflection.binding(for: "uniforms"),
            bindingsSplatDistancesIndex: try reflection.binding(for: "splatDistances"),
            bindingsSplatIndicesIndex: try reflection.binding(for: "splatIndices")
        )
    }

    public func compute(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws {
        if sortRate > 1 && info.frame > 1 && !info.frame.isMultiple(of: sortRate) {
            return
        }
        //        logger?.debug("GPU Sort: \(info.frame) / \(sortRate)")

        let computePipelineState = state.pipelineState

        let computePassDescriptor = MTLComputePassDescriptor()
        info.gpuCounters?.updateComputePassDescriptor(computePassDescriptor)
        let commandEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor).forceUnwrap()
        commandEncoder.label = "GaussianSplatBitonicSortComputePass"
        commandEncoder.withDebugGroup("GaussianSplatBitonicSortComputePass") {


            commandEncoder.setComputePipelineState(computePipelineState)

            commandEncoder.setBuffer(splats.indices, index: state.bindingsSplatIndicesIndex)
            commandEncoder.setBuffer(splats.distances, index: state.bindingsSplatDistancesIndex)
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
                        commandEncoder.setBytes(of: uniforms, index: state.bindingsUniformsIndex)
                        commandEncoder.dispatchThreadgroups(MTLSize(width: threadgroupsPerGrid), threadsPerThreadgroup: MTLSize(width: computePipelineState.maxTotalThreadsPerThreadgroup))
                    }
                }
            }
        }
        commandEncoder.endEncoding()
    }
}
