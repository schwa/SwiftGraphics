#include <simd/simd.h>


struct GaussianSplatVertexUniforms {
    simd_float4x4 modelViewProjectionMatrix;
};

struct GaussianSplatFragmentUniforms {
};

#ifdef __METAL_VERSION__
#include <metal_stdlib>

namespace GaussianSplatShader {

    using namespace metal;

    struct VertexIn {
        float3 position  [[attribute(0)]];
        float3 normal    [[attribute(1)]];
        float2 texCoords [[attribute(2)]];
    };

    struct VertexOut {
        float4 position [[position]];
        uint instance_id[[flat]];
    };

    struct Splat {
        packed_float3 position; // 3 floats for position (x, y, z)
        packed_float3 scales;   // 3 floats for scales (exp(scale_0), exp(scale_1), exp(scale_2))
        simd_uchar4 color;     // 4 uint8_t for color (r, g, b, opacity)
        simd_uchar4 rot;       // 4 uint8_t for normalized rotation (rot_0, rot_1, rot_2, rot_3) scaled to [0, 255]
    };


    typedef GaussianSplatVertexUniforms VertexUniforms;
    typedef GaussianSplatFragmentUniforms FragmentUniforms;
    typedef VertexOut FragmentIn;

    struct FragmentOut {
        float4 fragColor [[color(0)]];
    };

    // MARK: -

    [[vertex]]
    VertexOut VertexShader(
        VertexIn in [[stage_in]],
        uint instance_id[[instance_id]],
        constant VertexUniforms &uniforms [[buffer(1)]],
        constant Splat *splats [[buffer(2)]],
        constant uint *splatIndices [[buffer(3)]]
   ) {
        auto splat = splats[splatIndices[instance_id]];
        auto position = uniforms.modelViewProjectionMatrix * float4(splat.position + in.position, 1.0);
        return {
            .position = position,
            .instance_id = instance_id,
        };
    }

    [[fragment]]
    FragmentOut FragmentShader(
        FragmentIn in [[stage_in]],
        constant FragmentUniforms &uniforms [[buffer(0)]],
        constant Splat *splats [[buffer(1)]],
        constant uint *splatIndices [[buffer(3)]]
    ) {
        auto splat = splats[splatIndices[in.instance_id]];
        auto color = float4(splat.color) / 255.0;
        return {
            .fragColor = float4(color.xyz, 1)
        };
    }
}
#endif
