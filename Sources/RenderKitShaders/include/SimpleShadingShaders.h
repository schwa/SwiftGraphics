#pragma once

#include "Common.h"

#ifdef __METAL_VERSION__
#include <metal_stdlib>
using namespace metal;
#endif

struct SimpleShadingVertexShaderUniforms
{
    float4x4 modelViewMatrix;
    float4x4 modelViewProjectionMatrix;
    float3x3 modelNormalMatrix;
};

struct SimpleShadingFragmentShaderUniforms
{
    float3 materialDiffuseColor;
    float3 materialAmbientColor;
    float3 lightAmbientColor;
    float3 lightDiffuseColor;
    float3 lightPosition;
    float lightPower;
};
