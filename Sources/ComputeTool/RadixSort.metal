#include <metal_stdlib>
#include <simd/simd.h>
#include <metal_logging>

using namespace metal;

constant metal::os_log custom_log("com.custom_log.subsystem", "custom category");

//uint2 threads_per_grid [[threads_per_grid]],
//uint2 thread_position_in_threadgroup [[thread_position_in_threadgroup]],
//uint2 threadgroup_position_in_grid [[threadgroup_position_in_grid]],
//uint2 threadgroups_per_grid [[threadgroups_per_grid]],


[[kernel]]
void histogram(
    uint2 thread_position_in_grid [[thread_position_in_grid]],
    device uint *values [[buffer(0)]],
    constant uint &valuesCount [[buffer(1)]],
    constant uint &shift [[buffer(2)]],
    device atomic_uint *histogram [[buffer(3)]]
)
{
    const uchar bucket = thread_position_in_grid.x;
    const uint index = thread_position_in_grid.y;
    const uchar valueAtIndex = (values[index] >> shift) & 0xFF;
    atomic_fetch_add_explicit(&histogram[bucket], valueAtIndex == bucket, memory_order_relaxed);
}
