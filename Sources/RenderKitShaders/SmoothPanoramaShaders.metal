#include <metal_stdlib>
#include <simd/simd.h>

#import "include/RenderKitShaders.h"

using namespace metal;

typedef VertexIn SmoothPanoramaVertexIn;

struct SmoothPanoramaVertexOut {
    float4 position [[position]];
    float3 modelSpacePosition;
};

typedef SmoothPanoramaVertexOut SmoothPanoramaFragmentIn;

struct SmoothPanoramaFragmentOut {
    float4 fragColor [[color(0)]];
};

// MARK: -

vec2 uv_of_camera(vec3 modelSpacePosition, vec3 location, float rotation) {
    const float3 d = modelSpacePosition - location;
    const float r = length(d.xz);
    const float u = fract((atan2(d.x, -d.z) / M_PI_F + 1.0) * 0.5 - rotation / (M_PI_F * 2.0));
    const float v = atan2(d.y, r) / M_PI_F + 0.5;
    return { u, v };
}

// MARK: -

vertex SmoothPanoramaVertexOut SmoothPanoramaVertexShader(
    SmoothPanoramaVertexIn in [[stage_in]],
    constant SmoothPanoramaVertexShaderUniforms& uniforms [[buffer(1)]]
    )
{
    // TODO: Stop doing this per vertex.
    auto modelViewProjectionMatrix = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix;
    return {
        .position = modelViewProjectionMatrix * float4(in.position, 1),
        .modelSpacePosition = in.position,
    };
}

fragment SmoothPanoramaFragmentOut SmoothPanoramaFragmentShader(SmoothPanoramaFragmentIn in [[stage_in]],
    constant SmoothPanoramaFragmentShaderUniforms& uniforms [[buffer(0)]],
    texture2d<float> texture1 [[texture(0)]],
    texture2d<float> texture2 [[texture(1)]]
    )
{
    constexpr sampler defaultSampler(coord::normalized, s_address::repeat, t_address::clamp_to_edge, filter::nearest, mip_filter::none);
    float4 baseColor = { 0, 0, 0, 1 };

    if (uniforms.blendFactor <= 0) {
        const float2 uv = uv_of_camera(in.modelSpacePosition.xyz, uniforms.location1, uniforms.rotation1);
        baseColor = texture1.sample(defaultSampler, uv);
    }
    else if (uniforms.blendFactor >= 1) {
        const float2 uv = uv_of_camera(in.modelSpacePosition.xyz, uniforms.location2, uniforms.rotation2);
        baseColor = texture1.sample(defaultSampler, uv);
    }
    else {
        const float2 uv1 = uv_of_camera(in.modelSpacePosition.xyz, uniforms.location1, uniforms.rotation1);
        const float2 uv2 = uv_of_camera(in.modelSpacePosition.xyz, uniforms.location2, uniforms.rotation2);
        const auto texture1Color = texture1.sample(defaultSampler, uv1);
        const auto texture2Color = texture2.sample(defaultSampler, uv2);
        // TODO: become mix
        baseColor = (1.0 - uniforms.blendFactor) * texture1Color + uniforms.blendFactor * texture2Color;
    }
    return {
        .fragColor = baseColor
    };
}
