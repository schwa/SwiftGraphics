import BaseSupport
import GaussianSplatShaders
@preconcurrency import Metal
import MetalSupport
import RenderKit
import simd

// swiftlint:disable force_unwrapping

public struct GaussianSplatRadixSortComputePass: ComputePassProtocol {
    public struct State: PassState {
        var histogramPipelineState: MTLComputePipelineState
        var histogramShaderInputIndex: Int
        var histogramShaderHistogramIndex: Int
        var histogramShaderPassIndex: Int

        var scanPipelineState: MTLComputePipelineState
        var scanShaderHistogramIndex: Int

        var scatterPipelineState: MTLComputePipelineState
        var scatterShaderInputIndex: Int
        var scatterShaderOutputIndex: Int
        var scatterShaderHistogramIndex: Int
        var scatterShaderPassIndex: Int
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

        let histogramFunction = library.makeFunction(name: "GaussianSplatShaders::histogram").forceUnwrap("No function found")
        let (histogramPipelineState, histogramReflection) = try device.makeComputePipelineState(function: histogramFunction, options: .bindingInfo)

        let scanFunction = library.makeFunction(name: "GaussianSplatShaders::scan").forceUnwrap("No function found")
        let (scanPipelineState, scanReflection) = try device.makeComputePipelineState(function: scanFunction, options: .bindingInfo)

        let scatterFunction = library.makeFunction(name: "GaussianSplatShaders::scatter").forceUnwrap("No function found")
        let (scatterPipelineState, scatterReflection) = try device.makeComputePipelineState(function: scatterFunction, options: .bindingInfo)

        return State(
            histogramPipelineState: histogramPipelineState,
            histogramShaderInputIndex: try histogramReflection!.binding(for: "input"),
            histogramShaderHistogramIndex: try histogramReflection!.binding(for: "histogram"),
            histogramShaderPassIndex: try histogramReflection!.binding(for: "pass"),
            scanPipelineState: scanPipelineState,
            scanShaderHistogramIndex: try scanReflection!.binding(for: "histogram"),
            scatterPipelineState: scatterPipelineState,
            scatterShaderInputIndex: try scatterReflection!.binding(for: "input"),
            scatterShaderOutputIndex: try scatterReflection!.binding(for: "output"),
            scatterShaderHistogramIndex: try scatterReflection!.binding(for: "histogram"),
            scatterShaderPassIndex: try scatterReflection!.binding(for: "pass")
        )
    }

    public func compute(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws {
        //        let count = array.count
        //        var inputBuffer = device.makeBuffer(bytes: array, length: MemoryLayout<UInt32>.stride * count, options: [])!
        //        var outputBuffer = device.makeBuffer(length: MemoryLayout<UInt32>.stride * count, options: [])!
        //        let histogramBuffer = device.makeBuffer(length: MemoryLayout<UInt32>.stride * 256, options: [])!
        //
        //        let commandBuffer = commandQueue.makeCommandBuffer()!
        //
        //        for pass in 0..<4 {  // 4 passes for 32-bit integers
        //            // Reset histogram
        //            memset(histogramBuffer.contents(), 0, 256 * MemoryLayout<UInt32>.stride)
        //
        //            let histogramEncoder = commandBuffer.makeComputeCommandEncoder()!
        //            histogramEncoder.setComputePipelineState(histogramPipelineState)
        //            histogramEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        //            histogramEncoder.setBuffer(histogramBuffer, offset: 0, index: 1)
        //            histogramEncoder.setBytes([UInt32(pass)], length: MemoryLayout<UInt32>.stride, index: 2)
        //            histogramEncoder.dispatchThreads(MTLSizeMake(count, 1, 1), threadsPerThreadgroup: MTLSizeMake(256, 1, 1))
        //            histogramEncoder.endEncoding()
        //
        //            let scanEncoder = commandBuffer.makeComputeCommandEncoder()!
        //            scanEncoder.setComputePipelineState(scanPipelineState)
        //            scanEncoder.setBuffer(histogramBuffer, offset: 0, index: 0)
        //            scanEncoder.dispatchThreads(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
        //            scanEncoder.endEncoding()
        //
        //            let scatterEncoder = commandBuffer.makeComputeCommandEncoder()!
        //            scatterEncoder.setComputePipelineState(scatterPipelineState)
        //            scatterEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        //            scatterEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
        //            scatterEncoder.setBuffer(histogramBuffer, offset: 0, index: 2)
        //            scatterEncoder.setBytes([UInt32(pass)], length: MemoryLayout<UInt32>.stride, index: 3)
        //            scatterEncoder.dispatchThreads(MTLSizeMake(count, 1, 1), threadsPerThreadgroup: MTLSizeMake(256, 1, 1))
        //            scatterEncoder.endEncoding()
        //
        //            // Swap input and output buffers for the next pass
        //            swap(&inputBuffer, &outputBuffer)

    }
}

// import Metal
// import MetalKit
//
// class MetalRadixSort {
//    private let device: MTLDevice
//    private let commandQueue: MTLCommandQueue
//    private let library: MTLLibrary
//    private let histogramPipelineState: MTLComputePipelineState
//    private let scanPipelineState: MTLComputePipelineState
//    private let scatterPipelineState: MTLComputePipelineState
//
//    init?() {
//        guard let device = MTLCreateSystemDefaultDevice(),
//              let commandQueue = device.makeCommandQueue() else {
//            return nil
//        }
//
//        self.device = device
//        self.commandQueue = commandQueue
//
//        let shaderSource = """
//        #include <metal_stdlib>
//        using namespace metal;
//
//        kernel void histogram(device const uint* input [[buffer(0)]],
//                              device atomic_uint* histogram [[buffer(1)]],
//                              constant uint& pass [[buffer(2)]],
//                              uint id [[thread_position_in_grid]],
//                              uint threadcount [[threads_per_grid]]) {
//            for (uint i = id; i < threadcount; i += threadcount) {
//                uint value = input[i];
//                uint bucket = (value >> (pass * 8)) & 0xFF;
//                atomic_fetch_add_explicit(&histogram[bucket], 1, memory_order_relaxed);
//            }
//        }
//
//        kernel void scan(device atomic_uint* histogram [[buffer(0)]]) {
//            uint sum = 0;
//            for (uint i = 0; i < 256; i++) {
//                uint count = atomic_load_explicit(&histogram[i], memory_order_relaxed);
//                atomic_store_explicit(&histogram[i], sum, memory_order_relaxed);
//                sum += count;
//            }
//        }
//
//        kernel void scatter(device const uint* input [[buffer(0)]],
//                            device uint* output [[buffer(1)]],
//                            device const atomic_uint* histogram [[buffer(2)]],
//                            constant uint& pass [[buffer(3)]],
//                            uint id [[thread_position_in_grid]],
//                            uint threadcount [[threads_per_grid]]) {
//            for (uint i = id; i < threadcount; i += threadcount) {
//                uint value = input[i];
//                uint bucket = (value >> (pass * 8)) & 0xFF;
//                uint index = atomic_fetch_add_explicit((device atomic_uint*)&histogram[bucket], 1, memory_order_relaxed);
//                output[index] = value;
//            }
//        }
//        """
//
//        do {
//            self.library = try device.makeLibrary(source: shaderSource, options: nil)
//        } catch {
//            print("Failed to create Metal library: \(error)")
//            return nil
//        }
//
//        guard let histogramFunction = library.makeFunction(name: "histogram"),
//              let scanFunction = library.makeFunction(name: "scan"),
//              let scatterFunction = library.makeFunction(name: "scatter") else {
//            return nil
//        }
//
//        do {
//            histogramPipelineState = try device.makeComputePipelineState(function: histogramFunction)
//            scanPipelineState = try device.makeComputePipelineState(function: scanFunction)
//            scatterPipelineState = try device.makeComputePipelineState(function: scatterFunction)
//        } catch {
//            print("Failed to create pipeline state: \(error)")
//            return nil
//        }
//    }
//
//    func sort(_ array: [UInt32]) -> [UInt32] {
//        let count = array.count
//        var inputBuffer = device.makeBuffer(bytes: array, length: MemoryLayout<UInt32>.stride * count, options: [])!
//        var outputBuffer = device.makeBuffer(length: MemoryLayout<UInt32>.stride * count, options: [])!
//        let histogramBuffer = device.makeBuffer(length: MemoryLayout<UInt32>.stride * 256, options: [])!
//
//        let commandBuffer = commandQueue.makeCommandBuffer()!
//
//        for pass in 0..<4 {  // 4 passes for 32-bit integers
//            // Reset histogram
//            memset(histogramBuffer.contents(), 0, 256 * MemoryLayout<UInt32>.stride)
//
//            let histogramEncoder = commandBuffer.makeComputeCommandEncoder()!
//            histogramEncoder.setComputePipelineState(histogramPipelineState)
//            histogramEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
//            histogramEncoder.setBuffer(histogramBuffer, offset: 0, index: 1)
//            histogramEncoder.setBytes([UInt32(pass)], length: MemoryLayout<UInt32>.stride, index: 2)
//            histogramEncoder.dispatchThreads(MTLSizeMake(count, 1, 1), threadsPerThreadgroup: MTLSizeMake(256, 1, 1))
//            histogramEncoder.endEncoding()
//
//            let scanEncoder = commandBuffer.makeComputeCommandEncoder()!
//            scanEncoder.setComputePipelineState(scanPipelineState)
//            scanEncoder.setBuffer(histogramBuffer, offset: 0, index: 0)
//            scanEncoder.dispatchThreads(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
//            scanEncoder.endEncoding()
//
//            let scatterEncoder = commandBuffer.makeComputeCommandEncoder()!
//            scatterEncoder.setComputePipelineState(scatterPipelineState)
//            scatterEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
//            scatterEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
//            scatterEncoder.setBuffer(histogramBuffer, offset: 0, index: 2)
//            scatterEncoder.setBytes([UInt32(pass)], length: MemoryLayout<UInt32>.stride, index: 3)
//            scatterEncoder.dispatchThreads(MTLSizeMake(count, 1, 1), threadsPerThreadgroup: MTLSizeMake(256, 1, 1))
//            scatterEncoder.endEncoding()
//
//            // Swap input and output buffers for the next pass
//            swap(&inputBuffer, &outputBuffer)
//        }
//
//        commandBuffer.commit()
//        commandBuffer.waitUntilCompleted()
//
//        // The result is in the input buffer after an even number of passes
//        let resultPointer = inputBuffer.contents().bindMemory(to: UInt32.self, capacity: count)
//        return Array(UnsafeBufferPointer(start: resultPointer, count: count))
//    }
// }
//
//// Example usage
// func exampleUsage() {
//    guard let sorter = MetalRadixSort() else {
//        print("Failed to initialize MetalRadixSort")
//        return
//    }
//
//    let unsortedArray: [UInt32] = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 1000000, 500000, 2000000]
//    print("Unsorted array: \(unsortedArray)")
//
//    let sortedArray = sorter.sort(unsortedArray)
//    print("Sorted array: \(sortedArray)")
// }
//
//// Run the example
// exampleUsage()
