import BaseSupport
import GaussianSplatShaders
@preconcurrency import Metal
import MetalSupport
import RenderKit
import simd

public struct GaussianSplatDistanceComputePass: ComputePassProtocol {
    public struct State: PassState {
        var pipelineState: MTLComputePipelineState
        var bindings: Bindings
    }

    @MetalBindings
    struct Bindings {
        var modelMatrix: Int = -1
        var cameraPosition: Int = -1
        var splats: Int = -1
        var splatCount: Int = -1
        var indexedDistances: Int = -1
    }

    public var id = PassID("GaussianSplatPreCalcComputePass")
    var splats: SplatCloud
    var modelMatrix: simd_float3x3
    var cameraPosition: SIMD3<Float>
    var sortRate: Int

    public init(splats: SplatCloud, modelMatrix: simd_float3x3, cameraPosition: SIMD3<Float>, sortRate: Int) {
        self.splats = splats
        self.modelMatrix = modelMatrix
        self.cameraPosition = cameraPosition
        self.sortRate = sortRate
    }

    public func setup(device: MTLDevice) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .gaussianSplatShaders)
        let function = library.makeFunction(name: "GaussianSplatShaders::DistancePreCalc").forceUnwrap("No function found (found: \(library.functionNames))")
        let (pipelineState, reflection) = try device.makeComputePipelineState(function: function, options: .bindingInfo)
        var bindings = Bindings()
        try bindings.updateBindings(with: reflection)
        return State(
            pipelineState: pipelineState,
            bindings: bindings
        )
    }

    public func compute(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws {
        if sortRate > 1 && info.frame > 1 && !info.frame.isMultiple(of: sortRate) {
            return
        }
        let computePipelineState = state.pipelineState
        let commandEncoder = commandBuffer.makeComputeCommandEncoder().forceUnwrap()
        commandEncoder.label = "GaussianSplatPreCalcComputePass"
        commandEncoder.withDebugGroup("GaussianSplatPreCalcComputePass") {
            commandEncoder.setComputePipelineState(computePipelineState)
            commandEncoder.setBytes(of: modelMatrix, index: state.bindings.modelMatrix)
            commandEncoder.setBytes(of: cameraPosition, index: state.bindings.cameraPosition)
            commandEncoder.setBuffer(splats.splats, offset: 0, index: state.bindings.splats)
            commandEncoder.setBytes(of: UInt32(splats.splats.count), index: state.bindings.splatCount)
            commandEncoder.setBuffer(splats.indexedDistances, offset: 0, index: state.bindings.indexedDistances)
            let threadsPerThreadgroup = MTLSize(width: computePipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
            let numThreadgroups = (splats.splats.count + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width
            let threadgroupsPerGrid = MTLSize(width: numThreadgroups, height: 1, depth: 1)
            commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        }

        commandEncoder.endEncoding()
    }
}
