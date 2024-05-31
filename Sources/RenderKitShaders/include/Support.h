#pragma once

#ifdef __METAL_VERSION__
#include <metal_stdlib>
using namespace metal;

float4 kellyColor(float f);
float random(float2 p);
#endif
