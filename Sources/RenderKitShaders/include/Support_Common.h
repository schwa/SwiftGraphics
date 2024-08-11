
#if __METAL_VERSION__
    using namespace metal;
    #define TEXTURE2D(T...) texture2d<T>
    #define CONSTANT_PTR(T) constant T*
    #define DEVICE_PTR(T) device T*
    #define SAMPLER sampler
    #define ATTRIBUTE(T) [[attribute(T)]]

    #define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
    #define NSInteger metal::int32_t

    namespace RenderKitShaders {
        constexpr sampler basicSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    };
#else
    #define TEXTURE2D(T...) uint64_t
    #define CONSTANT_PTR(T) uint64_t
    #define DEVICE_PTR(T) uint64_t
    #define SAMPLER uint64_t
    #define ATTRIBUTE(T)

    #import <Foundation/Foundation.h>
    #import <simd/simd.h>
    typedef simd_float2 float2;
    typedef simd_float3 float3;
    typedef simd_float4 float4;
    typedef simd_float3x3 float3x3;
    typedef simd_float4x4 float4x4;

#endif

#if __METAL_VERSION__
struct SimpleVertex {
    float3 position             ATTRIBUTE(0);
    float3 normal               ATTRIBUTE(1);
    float2 textureCoordinate    ATTRIBUTE(2);
};
#endif

//struct ModelTransforms {
//    float4x4 modelViewMatrix; // model space -> camera space
//    float3x3 modelNormalMatrix; // model space - used for non-uniform scaled normal transformation. See https://www.youtube.com/watch?v=esC1HnyD9Bk&list=PLplnkTzzqsZS3R5DjmCQsqupu43oS9CFN
//};
//
//struct CameraUniforms {
//    float4x4 projectionMatrix;
//};
