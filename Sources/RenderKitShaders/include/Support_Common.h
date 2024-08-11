#pragma once

#ifdef __METAL_VERSION__
using namespace metal;
typedef simd_float2 vec2;
typedef simd_float2 vec2;
typedef simd_float3 vec3;
typedef simd_float4 vec4;
#else
typedef simd_float2 float2;
typedef simd_float3 float3;
typedef simd_float4 float4;
typedef simd_float3x3 float3x3;
typedef simd_float4x4 float4x4;
#endif

#ifdef __METAL_VERSION__
// TODO: Deprecate
struct VertexIn {
    float3 position  [[attribute(0)]];
    float3 normal    [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};
#else
// TODO: Deprecate
struct VertexIn {
    float3 position;
    float3 normal;
    float2 texCoords;
};
#endif
