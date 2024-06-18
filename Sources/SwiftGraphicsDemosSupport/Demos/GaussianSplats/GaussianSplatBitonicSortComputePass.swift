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
        var bindingsSplatsIndex: Int
        var bindingsSplatIndicesIndex: Int
    }

    var id = AnyHashable("GaussianSplatBitonicSortComputePass")
    var splatCount: Int
    var splatIndicesBuffer: Box<MTLBuffer>
    var splatBuffer: Box<MTLBuffer>
    var modelMatrix: simd_float3x3
    var cameraPosition: float3

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
            bindingsSplatsIndex: try reflection.binding(for: "splats"),
            bindingsSplatIndicesIndex: try reflection.binding(for: "splatIndices")
        )
        return state
    }

    func compute(device: MTLDevice, state: State, commandBuffer: MTLCommandBuffer) throws {
        let computePipelineState = state.pipelineState
        let commandEncoder = commandBuffer.makeComputeCommandEncoder().forceUnwrap()
        commandEncoder.label = "GaussianSplatBitonicSortComputePass"
        commandEncoder.withDebugGroup("GaussianSplatBitonicSortComputePass") {
            commandEncoder.setComputePipelineState(computePipelineState)

            commandEncoder.setBuffer(splatIndicesBuffer.content, offset: 0, index: state.bindingsSplatIndicesIndex)
            commandEncoder.setBuffer(splatBuffer.content, offset: 0, index: state.bindingsSplatsIndex)

            let numStages = Int(log2(nextPowerOfTwo(Double(splatCount))))
            var threadgroupsPerGrid = (splatCount + computePipelineState.maxTotalThreadsPerThreadgroup - 1) / computePipelineState.maxTotalThreadsPerThreadgroup
            threadgroupsPerGrid = (threadgroupsPerGrid + computePipelineState.threadExecutionWidth - 1) / computePipelineState.threadExecutionWidth * computePipelineState.threadExecutionWidth
            for stageIndex in 0 ..< numStages {
                commandEncoder.withDebugGroup("Stage \(stageIndex) of \(numStages)") {
                    for stepIndex in 0 ..< (stageIndex + 1) {
                        let groupWidth = 1 << (stageIndex - stepIndex)
                        let groupHeight = 2 * groupWidth - 1

                        // TODO: Changing all the uniforms per call() is a bit over the top but hey.
                        let uniforms = GaussianSplatSortUniforms(splatCount: UInt32(splatCount), groupWidth: UInt32(groupWidth), groupHeight: UInt32(groupHeight), stepIndex: UInt32(stepIndex), modelMatrix: modelMatrix, cameraPosition: cameraPosition)
                        commandEncoder.setBytes(of: uniforms, index: state.bindingsUniformsIndex)
                        commandEncoder.dispatchThreadgroups(MTLSize(width: threadgroupsPerGrid), threadsPerThreadgroup: MTLSize(width: computePipelineState.maxTotalThreadsPerThreadgroup))
                    }
                }
            }
        }
        commandEncoder.endEncoding()
    }
}

public func nextPowerOfTwo(_ value: Double) -> Double {
    let logValue = log2(Double(value))
    let nextPower = pow(2.0, ceil(logValue))
    return nextPower
}

public func nextPowerOfTwo(_ value: Int) -> Int {
    Int(nextPowerOfTwo(Double(value)))
}

public extension MTLSize {
    init(width: Int) {
        self = MTLSize(width: width, height: 1, depth: 1)
    }
}

extension MTLComputeCommandEncoder {
    func setBytes(_ bytes: UnsafeRawBufferPointer, index: Int) {
        setBytes(bytes.baseAddress!, length: bytes.count, index: index)
    }

    func setBytes(of value: some Any, index: Int) {
        withUnsafeBytes(of: value) { buffer in
            setBytes(buffer, index: index)
        }
    }

    func setBytes(of value: [some Any], index: Int) {
        value.withUnsafeBytes { buffer in
            setBytes(buffer, index: index)
        }
    }
}
