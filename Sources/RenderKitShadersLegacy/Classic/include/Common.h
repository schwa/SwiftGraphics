#pragma once

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#include <metal_stdlib>
#else
#import <Foundation/Foundation.h>
#endif

#import <simd/simd.h>

struct FrameState {
//    simd_float4x4 projection; // camera space -> clip space
//    simd_float2 drawableSize;
    float time;
//    float lastTime;
    long frame;
    float desiredFPS;
    // apply gamma correction (assume ambientColor, diffuseColor and specularColor have been linearized, i.e. have no gamma correction in them)
    // Assume the monitor is calibrated to the sRGB color space
    float screenGamma;  // 2.2
};


struct Transforms { // Rename to ModelState?
    simd_float4x4 modelView; // model space -> camera space
    simd_float3x3 modelNormal; // model space - used for non-uniform scaled normal transformation. See https://www.youtube.com/watch?v=esC1HnyD9Bk&list=PLplnkTzzqsZS3R5DjmCQsqupu43oS9CFN
    simd_float4x4 projection; // Move to WorldState?
};

struct Vertex {
#ifdef __METAL_VERSION__
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 textureCoordinate [[attribute(2)]];
#else
    simd_float3 position;
    simd_float3 normal;
    simd_float2 textureCoordinate;
    // tangents etc
#endif
};
