#include <simd/simd.h>

struct PointCloudVertexUniforms {
    simd_float4x4 modelViewProjectionMatrix;
};

struct PointCloudFragmentUniforms {
};

#ifdef __METAL_VERSION__
#include <metal_stdlib>

namespace PointCloudShader {

    using namespace metal;

    struct VertexIn {
        float3 position  [[attribute(0)]];
        float3 normal    [[attribute(1)]];
        float2 texCoords [[attribute(2)]];
    };

    struct VertexOut {
        float4 position [[position]];
    };

    typedef PointCloudVertexUniforms VertexUniforms;
    typedef PointCloudFragmentUniforms FragmentUniforms;
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
        constant float3 *positions [[buffer(2)]]
    ) {
        return {
            .position = uniforms.modelViewProjectionMatrix * float4(positions[instance_id] + in.position, 1.0),
        };
    }

    [[fragment]]
    FragmentOut FragmentShader(
        FragmentIn in [[stage_in]],
        constant FragmentUniforms &uniforms [[buffer(0)]]
    ) {
        return {
            .fragColor = { 1, 0, 1, 1}
        };
    }
}
#endif
