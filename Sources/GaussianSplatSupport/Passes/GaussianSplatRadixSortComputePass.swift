import BaseSupport
import GaussianSplatShaders
@preconcurrency import Metal
import MetalSupport
import RenderKit
import simd

public struct GaussianSplatRadixSortComputePass: ComputePassProtocol {
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
//        let library = try device.makeDebugLibrary(bundle: .gaussianSplatShaders)
//        let function = library.makeFunction(name: "GaussianSplatShaders::BitonicSortSplats").forceUnwrap("No function found")
//        let (pipelineState, reflection) = try device.makeComputePipelineState(function: function, options: .bindingInfo)
//        guard let reflection else {
//            fatalError("Failed to create pipeline state.")
//        }
//        return State(
//            pipelineState: pipelineState,
//            bindingsUniformsIndex: try reflection.binding(for: "uniforms"),
//            bindingsSplatDistancesIndex: try reflection.binding(for: "splatDistances"),
//            bindingsSplatIndicesIndex: try reflection.binding(for: "splatIndices")
//        )
        fatalError()
    }

    public func compute(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws {

    }
}
