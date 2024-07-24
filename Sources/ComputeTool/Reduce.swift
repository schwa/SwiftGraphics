import Compute
import Metal
import MetalSupport

let source = #"""
#include <metal_stdlib>

using namespace metal;

kernel void parallel_reduction_sum(
    const device float* input [[buffer(0)]],
    device float* output [[buffer(1)]],
    uint thread_position_in_grid [[thread_position_in_grid]],
    uint simdgroup_index_in_threadgroup [[simdgroup_index_in_threadgroup]],
    uint threads_per_simdgroup [[threads_per_simdgroup]]
)
{
    // load value
    float value = input[thread_position_in_grid];
    // Perform parallel reduction within SIMD group
    for (uint offset = threads_per_simdgroup / 2; offset > 0; offset >>= 1) {
        value += simd_shuffle_down(value, offset);
    }
    // Only the first thread in each SIMD group writes the result
    if (simd_is_first()) {
        output[simdgroup_index_in_threadgroup] = value;
    }
}
"""#

struct Reduce {
    let device = MTLCreateSystemDefaultDevice()!

    func main() throws  {
        // Create N values and sum them up in the CPU...
        var count = 5000
        let values = (0..<count).map({ Float($0 + 1) })
        print("Expected result:", values.reduce(0, +))
        // Create input and output metal buffers to work in... fill the input buffer with our sample data
        var input = try device.makeBuffer(bytesOf: values, options: [])
        var output = try device.makeBuffer(bytesOf: Array(repeating: Float.zero, count: count), options: [])
        // Create a "Compute" object
        let compute = try Compute(device: device)
        // Create a shader library from our source string
        let library = ShaderLibrary.source(source)
        // Create a compute pass from our function
        var pass = try compute.makePass(function: library.parallel_reduction_sum)
        // Save the threadExecutionWidth (always 32 on current Apple Silicon). The number of threads that work per simd group.
        let threadExecutionWidth = pass.computePipelineState.threadExecutionWidth
        // We'll be running this until we have one count elft
        while count > 1 {
            print(count)
            // Load our buffers into the pass
            pass.arguments.input = .buffer(input)
            pass.arguments.output = .buffer(output)
            // Perform one dispatch on the pass
            try compute.task { task in
                try task { dispatch in
                    let maxTotalThreadsPerThreadgroup = pass.computePipelineState.maxTotalThreadsPerThreadgroup
                    try dispatch(pass: pass, threads: MTLSize(width: count), threadsPerThreadgroup: MTLSize(width: maxTotalThreadsPerThreadgroup))
                }
            }
            // For the next run we'll be doing less work... The output buffer contains input.count / threadExecutionWidth results...
            count = (count + threadExecutionWidth - 1) / threadExecutionWidth
            // If we're not done yet swap the buffers....
            if count != 1 {
                swap(&input, &output)
            }
        }
        print("Compute result:", Array(output.contentsBuffer(of: Float.self))[0])
    }
}
