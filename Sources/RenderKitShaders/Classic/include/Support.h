#pragma once

#import <simd/simd.h>

#ifdef __METAL_VERSION__

#include <metal_stdlib>

using namespace metal;

extern float3 GammaCorrect(float3 color, float screenGamma);
#endif
