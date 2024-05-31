#pragma once

#include "Common.h"

#ifdef __METAL_VERSION__
#include <metal_stdlib>
using namespace metal;
#endif

struct DebugVertexShaderUniforms
{
    float4x4 modelViewProjectionMatrix;
    float3 positionOffset;
};

struct DebugFragmentShaderUniforms
{
    float2 windowSize;
};
