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
        auto splat = splats[splatIndices[instance_id]];
        out.position = uniforms.modelViewProjectionMatrix * float4(float3(splat.position) + in.position, 1.0),
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