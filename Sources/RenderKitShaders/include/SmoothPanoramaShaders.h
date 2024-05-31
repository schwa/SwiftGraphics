#pragma once

#ifdef __METAL_VERSION__
#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;
#endif

#include "Common.h"

struct SmoothPanoramaVertexShaderUniforms
{
    // TODO: For now pass in all matrixes until we know which we're using...
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
};

struct SmoothPanoramaFragmentShaderUniforms
{
    float3 location1;
    float rotation1;
    float3 location2;
    float rotation2;
    float blendFactor;
};
