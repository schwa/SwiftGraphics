#pragma once

#ifdef __METAL_VERSION__
#include <metal_stdlib>
using namespace metal;
#endif

#import <simd/simd.h>

#import "Common.h"

struct BlinnPhongLight {
    simd_float3 lightPosition;
    simd_float3 lightColor;
    float lightPower;
};

#ifdef __METAL_VERSION__
struct BlinnPhongMaterialArgumentBuffer {
    texture2d<float, access::sample> ambientTexture;
    sampler ambientSampler;
    texture2d<float, access::sample> diffuseTexture;
    sampler diffuseSampler;
    texture2d<float, access::sample> specularTexture;
    sampler specularSampler;
    float shininess;
};

struct BlinnPhongLightingModelArgumentBuffer {
    float screenGamma; // TODO: Move
    int lightCount;
    simd_float3 ambientLightColor; // TODO
    device BlinnPhongLight *lights;
};

float3 CalculateBlinnPhong(float3 modelPosition,
                           float3 interpolatedNormal,
                           constant BlinnPhongLightingModelArgumentBuffer &lightingModel,
                           float shininess,
                           float3 ambientColor,
                           float3 diffuseColor,
                           float3 specularColor
                           );
#endif
