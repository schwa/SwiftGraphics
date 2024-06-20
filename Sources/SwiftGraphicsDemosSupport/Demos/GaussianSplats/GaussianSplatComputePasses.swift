import Metal
import RenderKit
import RenderKitShaders
import simd

extension MTLDevice {
    func makeComputePipelineState(function: MTLFunction, options: MTLPipelineOption) throws -> (MTLComputePipelineState, MTLComputePipelineReflection?) {
        var reflection: MTLComputePipelineReflection?
        let pipelineState = try makeComputePipelineState(function: function, options: options, reflection: &reflection)
        return (pipelineState, reflection)
    }
}

struct GaussianSplatBitonicSortComputePass: ComputePassProtocol {
    struct State: PassState {
        var pipelineState: MTLComputePipelineState
        var bindingsUniformsIndex: Int
        var bindingsSplatDistancesIndex: Int
        var bindingsSplatIndicesIndex: Int
    }

    var id = AnyHashable("GaussianSplatBitonicSortComputePass")
    var splatCount: Int
    var splatIndicesBuffer: Box<MTLBuffer>
    var splatDistancesBuffer: Box<MTLBuffer>

    func setup(device: MTLDevice) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .renderKitShaders)
        let function = library.makeFunction(name: "GaussianSplatShader::BitonicSortSplats").forceUnwrap("No function found")
        let (pipelineState, reflection) = try device.makeComputePipelineState(function: function, options: .bindingInfo)
        guard let reflection else {
            fatalError()
        }
        let state = State(
            pipelineState: pipelineState,
            bindingsUniformsIndex: try reflection.binding(for: "uniforms"),
            bindingsSplatDistancesIndex: try reflection.binding(for: "splatDistances"),
            bindingsSplatIndicesIndex: try reflection.binding(for: "splatIndices")
        )
        return state
    }

    func compute(device: MTLDevice, state: inout State, commandBuffer: MTLCommandBuffer) throws {
        let computePipelineState = state.pipelineState
        let commandEncoder = commandBuffer.makeComputeCommandEncoder().forceUnwrap()
        commandEncoder.label = "GaussianSplatBitonicSortComputePass"
        commandEncoder.withDebugGroup("GaussianSplatBitonicSortComputePass") {
            commandEncoder.setComputePipelineState(computePipelineState)

            commandEncoder.setBuffer(splatIndicesBuffer.content, offset: 0, index: state.bindingsSplatIndicesIndex)
            commandEncoder.setBuffer(splatDistancesBuffer.content, offset: 0, index: state.bindingsSplatDistancesIndex)

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


struct GaussianSplatPreCalcComputePass: ComputePassProtocol {
    struct State: PassState {
        var pipelineState: MTLComputePipelineState
        var bindingsModelMatrixIndex: Int
        var bindingsCameraPositionIndex: Int
        var bindingsSplatsIndex: Int
        var bindingsSplatCountIndex: Int
        var bindingsSplatDistancesIndex: Int
    }

    var id = AnyHashable("GaussianSplatPreCalcComputePass")
    var splatCount: Int
    var splatDistancesBuffer: Box<MTLBuffer>
    var splatBuffer: Box<MTLBuffer>
    var modelMatrix: simd_float3x3
    var cameraPosition: float3

    func setup(device: MTLDevice) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .renderKitShaders)
        let function = library.makeFunction(name: "GaussianSplatShader::DistancePreCalc").forceUnwrap("No function found")
        let (pipelineState, reflection) = try device.makeComputePipelineState(function: function, options: .bindingInfo)
        guard let reflection else {
            fatalError()
        }
        let state = State(
            pipelineState: pipelineState,
            bindingsModelMatrixIndex: try reflection.binding(for: "modelMatrix"),
            bindingsCameraPositionIndex: try reflection.binding(for: "cameraPosition"),
            bindingsSplatsIndex: try reflection.binding(for: "splats"),
            bindingsSplatCountIndex: try reflection.binding(for: "splatCount"),
            bindingsSplatDistancesIndex: try reflection.binding(for: "splatDistances")
        )
        return state
    }

    func compute(device: MTLDevice, state: inout State, commandBuffer: MTLCommandBuffer) throws {
        let computePipelineState = state.pipelineState
        let commandEncoder = commandBuffer.makeComputeCommandEncoder().forceUnwrap()
        commandEncoder.label = "GaussianSplatPreCalcComputePass"
        commandEncoder.withDebugGroup("GaussianSplatPreCalcComputePass") {
            commandEncoder.setComputePipelineState(computePipelineState)
            commandEncoder.setBytes(of: modelMatrix, index: state.bindingsModelMatrixIndex)
            commandEncoder.setBytes(of: cameraPosition, index: state.bindingsCameraPositionIndex)
            commandEncoder.setBuffer(splatBuffer.content, offset: 0, index: state.bindingsSplatsIndex)
            commandEncoder.setBytes(of: splatCount, index: state.bindingsSplatCountIndex)
            commandEncoder.setBuffer(splatDistancesBuffer.content, offset: 0, index: state.bindingsSplatDistancesIndex)
            let threadsPerThreadgroup = MTLSize(width: computePipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
            let numThreadgroups = (splatCount + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width
            let threadgroupsPerGrid = MTLSize(width: numThreadgroups, height: 1, depth: 1)
            commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        }

        commandEncoder.endEncoding()
    }
}
