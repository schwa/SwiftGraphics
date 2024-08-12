#import <simd/simd.h>

#ifndef __METAL_VERSION__
typedef simd_float2 float2;
typedef simd_float3 float3;
typedef simd_float4 float4;
typedef simd_float3x3 float3x3;
typedef simd_float4x4 float4x4;
#endif

#pragma pack(push, 1)
struct VolumeTransforms {
    simd_float4x4 modelViewMatrix;
    simd_float4x4 textureMatrix;
};
#pragma pack(pop)

#pragma pack(push, 1)
struct VolumeFragmentUniforms {
    unsigned short instanceCount;
    unsigned short maxValue;
    float alpha;
};
#pragma pack(pop)


#pragma pack(push, 1)
struct VolumeInstance {
    float offsetZ;
    float textureZ;
};
#pragma pack(pop)
