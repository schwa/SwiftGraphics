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

#endif
