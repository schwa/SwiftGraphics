import BaseSupport
import GaussianSplatShaders
@preconcurrency import Metal
import MetalSupport
import RenderKit
import simd

public struct GaussianSplatDistanceComputePass: ComputePassProtocol {
    public struct State: PassState {
        var pipelineState: MTLComputePipelineState
        var bindingsModelMatrixIndex: Int
        var bindingsCameraPositionIndex: Int
        var bindingsSplatsIndex: Int
        var bindingsSplatCountIndex: Int
        var bindingsSplatDistancesIndex: Int
    }

    public var id = PassID("GaussianSplatPreCalcComputePass")
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
            fatalError("Failed to create pipeline state")
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

    public func compute(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws {
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
