#include <metal_stdlib>
#include <simd/simd.h>
#include "include/Shaders.h"

using namespace metal;

kernel void checkerboard(
    uint2 gid [[thread_position_in_grid]],
    uint2 grid_size [[grid_size]],
    texture2d<float, access::write> outputTexture [[texture(CheckerBoardComputeBindings_OutputTexture)]],
    constant float2 &size [[buffer(CheckerBoardComputeBindings_SizeBuffer)]])
{
    float2 t = fmod(float2(gid), size) / size;

    float v1 = t.x >= 0.5 ? 1.0 : 0;
    float v2 = t.y >= 0.5 ? v1 : 1 - v1;

    outputTexture.write(float4(v2, 0, v2, 1), gid);
}
