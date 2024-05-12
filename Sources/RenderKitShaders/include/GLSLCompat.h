#pragma once

#ifdef __METAL_VERSION__
#include <metal_stdlib>
#endif

using namespace metal;

namespace glslCompatible {
// GLSL Compat

typedef float2 vec2;
typedef float3 vec3;
typedef float4 vec4;

inline float2 mod(float2 lhs, float rhs) {
    return fmod(lhs, rhs);
}

inline float3 mod(float3 lhs, float rhs) {
    return fmod(lhs, rhs);
}

inline float3 mod(float3 lhs, float3 rhs) {
    return fmod(lhs, rhs);
}

inline float3 frac(float3 v) {
    return fract(v);
}

inline float2 frac(float2 v) {
    return fract(v);
}

inline float frac(float v) {
    return fract(v);
}


// MARK: -

//inline float random (vec2 st) {
//    return fract(sin(dot(st.xy,
//                         vec2(12.9898,78.233)))*
//                 43758.5453123);
//}

//// MARK: -
//
//inline float rand2dTo1d(vec2 input) {
//    return random(input);
//}
//
////inline float rand3dTo1d(vec3 input) {
////    return random(input);
////}
//
//inline vec2 rand2dTo2d(vec2 input) {
//    auto x = random(vec2(input.x * 2, input.y));
//    auto y = random(vec2(input.x * 2 + 1, input.y));
//    return vec2(x, y);
//}
//
//inline float3 rand1dTo3d(float input) {
//    return float3(
//                  random(input * 3),
//                  random(input * 3 + 1),
//                  random(input * 3 + 2)
//                  );
//}
}
