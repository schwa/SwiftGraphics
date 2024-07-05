#import <simd/simd.h>

#import "GaussianSplatSupport.h"

#ifdef __METAL_VERSION__
#import <metal_stdlib>

namespace GaussianSplatShaders {

    using namespace metal;

    typedef SplatC Splat;
    typedef GaussianSplatUniforms VertexUniforms;
    typedef GaussianSplatUniforms FragmentUniforms;
    typedef VertexOut FragmentIn;

    // MARK: -

    [[vertex]]
    VertexOut VertexPointShader(
        VertexIn in [[stage_in]],
        uint instance_id[[instance_id]],
        uint vertex_id[[vertex_id]],
        constant VertexUniforms &uniforms [[buffer(1)]],
        constant Splat *splats [[buffer(2)]],
        constant uint *splatIndices [[buffer(3)]]
   ) {
        VertexOut out;

//        const float2 vertexModelSpacePosition = in.position.xy;
        auto splat = splats[splatIndices[instance_id]];
//        const float4 splatWorldSpacePosition = uniforms.modelViewMatrix * float4(float3(splat.position), 1);
//        const float4 splatClipSpacePosition = uniforms.projectionMatrix * splatWorldSpacePosition;
//
//
//        // float3 calcCovariance2D(float3 viewPos, packed_half3 cov3Da, packed_half3 cov3Db, float4x4 viewMatrix, float4x4 projectionMatrix, float2 screenSize)
//        const float3 cov2D = calcCovariance2D(splatWorldSpacePosition.xyz, splat.cov_a, splat.cov_b, uniforms.viewMatrix, uniforms.projectionMatrix, uniforms.drawableSize);
//        const Tuple2<float2> axes = decomposeCovariance(cov2D);
//
//        const float2 projectedScreenDelta = (vertexModelSpacePosition.x * axes.v0 + vertexModelSpacePosition.y * axes.v1) * 2 * kBoundsRadius / uniforms.drawableSize;
//        out.position = splatClipSpacePosition + float4(projectedScreenDelta.xy * splatClipSpacePosition.w, 0, 0);
//        out.relativePosition = vertexModelSpacePosition * kBoundsRadius;
        out.position = uniforms.modelViewProjectionMatrix * float4(float3(splat.position * 0.0001) + in.position, 1.0),
        out.color = float4(splat.color);
        return out;
    }

    // MARK: -

    [[fragment]]
    float4 FragmentPointShader(
        FragmentIn in [[stage_in]],
        constant FragmentUniforms &uniforms [[buffer(0)]],
        constant Splat *splats [[buffer(1)]],
        constant uint *splatIndices [[buffer(3)]]
    ) {
        return in.color;
    }
}
#endif // __METAL_VERSION__
