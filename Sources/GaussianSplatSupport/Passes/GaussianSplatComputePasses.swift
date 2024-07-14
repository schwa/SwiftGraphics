import BaseSupport
import GaussianSplatShaders
import Metal
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

    public var id = AnyHashable("GaussianSplatBitonicSortComputePass")
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
            fatalError()
        }
        return State(
            pipelineState: pipelineState,
            bindingsUniformsIndex: try reflection.binding(for: "uniforms"),
            bindingsSplatDistancesIndex: try reflection.binding(for: "splatDistances"),
            bindingsSplatIndicesIndex: try reflection.binding(for: "splatIndices")
        )
    }

    public func compute(commandBuffer: MTLCommandBuffer, info: PassInfo, state: inout State) throws {
        state.frameCount += 1
        if sortRate > 1 && state.frameCount > 1 && !state.frameCount.isMultiple(of: sortRate) {
            return
        }

        let computePipelineState = state.pipelineState
        let commandEncoder = commandBuffer.makeComputeCommandEncoder().forceUnwrap()
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

public struct GaussianSplatPreCalcComputePass: ComputePassProtocol {
    public struct State: PassState {
        var pipelineState: MTLComputePipelineState
        var bindingsModelMatrixIndex: Int
        var bindingsCameraPositionIndex: Int
        var bindingsSplatsIndex: Int
        var bindingsSplatCountIndex: Int
        var bindingsSplatDistancesIndex: Int
    }

    public var id = AnyHashable("GaussianSplatPreCalcComputePass")
    var splats: SplatCloud
    var modelMatrix: simd_float3x3
    var cameraPosition: SIMD3<Float>

    public init(splats: SplatCloud, modelMatrix: simd_float3x3, cameraPosition: SIMD3<Float>) {
        self.splats = splats
        self.modelMatrix = modelMatrix
        self.cameraPosition = cameraPosition
    }

    public func setup(device: MTLDevice) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .gaussianSplatShaders)
        let function = library.makeFunction(name: "GaussianSplatShaders::DistancePreCalc").forceUnwrap("No function found (found: \(library.functionNames))")
        let (pipelineState, reflection) = try device.makeComputePipelineState(function: function, options: .bindingInfo)
        guard let reflection else {
            fatalError()
        }
        return State(
            pipelineState: pipelineState,
            bindingsModelMatrixIndex: try reflection.binding(for: "modelMatrix"),
            bindingsCameraPositionIndex: try reflection.binding(for: "cameraPosition"),
            bindingsSplatsIndex: try reflection.binding(for: "splats"),
            bindingsSplatCountIndex: try reflection.binding(for: "splatCount"),
            bindingsSplatDistancesIndex: try reflection.binding(for: "splatDistances")
        )
    }

    public func compute(commandBuffer: MTLCommandBuffer, info: PassInfo, state: inout State) throws {
        let computePipelineState = state.pipelineState
        let commandEncoder = commandBuffer.makeComputeCommandEncoder().forceUnwrap()
        commandEncoder.label = "GaussianSplatPreCalcComputePass"
        commandEncoder.withDebugGroup("GaussianSplatPreCalcComputePass") {
            commandEncoder.setComputePipelineState(computePipelineState)
            commandEncoder.setBytes(of: modelMatrix, index: state.bindingsModelMatrixIndex)
            commandEncoder.setBytes(of: cameraPosition, index: state.bindingsCameraPositionIndex)
            commandEncoder.setBuffer(splats.splats, index: state.bindingsSplatsIndex)
            commandEncoder.setBytes(of: UInt32(splats.splats.count), index: state.bindingsSplatCountIndex)
            commandEncoder.setBuffer(splats.distances, index: state.bindingsSplatDistancesIndex)
            let threadsPerThreadgroup = MTLSize(width: computePipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
            let numThreadgroups = (splats.splats.count + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width
            let threadgroupsPerGrid = MTLSize(width: numThreadgroups, height: 1, depth: 1)
            commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        }

        commandEncoder.endEncoding()
    }
}
