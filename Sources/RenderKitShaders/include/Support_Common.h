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
struct SimpleVertex {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 textureCoordinate [[attribute(2)]];
};
#else
// TODO: Deprecate
struct VertexIn {
    float3 position;
    float3 normal;
    float2 texCoords;
};
#endif

struct ModelTransforms {
    float4x4 modelViewMatrix; // model space -> camera space
    float3x3 modelNormalMatrix; // model space - used for non-uniform scaled normal transformation. See https://www.youtube.com/watch?v=esC1HnyD9Bk&list=PLplnkTzzqsZS3R5DjmCQsqupu43oS9CFN
};

// TODO: DEPRECATE
struct ModelUniforms {
    float4x4 modelViewMatrix; // model space -> camera space
    float3x3 modelNormalMatrix; // model space - used for non-uniform scaled normal transformation. See https://www.youtube.com/watch?v=esC1HnyD9Bk&list=PLplnkTzzqsZS3R5DjmCQsqupu43oS9CFN
    float4 color;
};

struct CameraUniforms {
    float4x4 projectionMatrix;
};

struct LightUniforms {
    // Per diffuse light
    float3 lightPosition;
    float3 lightColor;
    float lightPower;
    // Per environment
    float3 ambientLightColor;
};

#ifndef __METAL_VERSION__

#import <Foundation/Foundation.h>
#import <simd/simd.h>

typedef simd_float2 float2;
typedef simd_float3 float3;
typedef simd_float4 float4;
typedef simd_float3x3 float3x3;
typedef simd_float4x4 float4x4;

#else

#import <simd/simd.h>
#import <metal_stdlib>

#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t

using namespace metal;

namespace RenderKitShaders {
    constexpr sampler basicSampler(coord::normalized, address::clamp_to_edge, filter::linear);
};

template<typename T> T srgb_to_linear(T c) {
    if (c <= 0.04045) {
        return c / 12.92;
    }
    else {
        return powr((c + 0.055) / 1.055, 2.4);
    }
}

inline float3 srgb_to_linear(float3 c) {
    return float3(srgb_to_linear(c.x), srgb_to_linear(c.y), srgb_to_linear(c.z));
}

inline float4 srgb_to_linear(float4 c) {
    return float4(srgb_to_linear(c.xyz), c.a);
}

template<typename T> T linear_to_srgb(T c) {
    if (isnan(c)) {
        return 0.0;
    }
    else if (c > 1.0) {
        return 1.0;
    }
    else {
        return (c < 0.0031308f) ? (12.92f * c) : (1.055 * powr(c, 1.0 / 2.4) - 0.055);
    }
}

inline float3 linear_to_srgb(float3 c) {
    return float3(linear_to_srgb(c.x), linear_to_srgb(c.y), linear_to_srgb(c.z));
}

inline float4 linear_to_srgb(float4 c) {
    return float4(linear_to_srgb(c.xyz), c.a);
}
#endif

#if __METAL_VERSION__
    using namespace metal;
    #define TEXTURE2D(T...) texture2d<T>
    #define CONSTANT_PTR(T) constant T*
    #define DEVICE_PTR(T) device T*
    #define SAMPLER sampler
#else
    #define TEXTURE2D(T...) uint64_t
    #define CONSTANT_PTR(T) uint64_t
    #define DEVICE_PTR(T) uint64_t
    #define SAMPLER uint64_t
#endif
