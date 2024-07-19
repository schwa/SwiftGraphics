#import <simd/simd.h>

#import "GaussianSplatSupport.h"

#if __METAL_VERSION__
#define ATOMIC_UINT atomic_uint
#else
#define ATOMIC_UINT unsigned int
#endif

struct MyCounters {
    ATOMIC_UINT vertices_submitted;
    ATOMIC_UINT vertices_culled;
};

#ifdef __METAL_VERSION__
#import <metal_stdlib>

constant bool use_counters [[function_constant(0)]];

namespace GaussianSplatShaders {

    using namespace metal;

    struct VertexIn {
        float3 position [[attribute(0)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float2 relativePosition; // Ranges from -kBoundsRadius to +kBoundsRadius
        float4 color;
    };

    struct FragmentOut {
        float4 fragColor [[color(0)]];
    };

    typedef SplatC Splat;
    typedef GaussianSplatUniforms VertexUniforms;
    typedef GaussianSplatUniforms FragmentUniforms;
    typedef VertexOut FragmentIn;

    // MARK: -

    constant static const float kBoundsRadius = 2;
    constant static const float kBoundsRadiusSquared = kBoundsRadius * kBoundsRadius;

    [[vertex]]
    VertexOut VertexShader(
        VertexIn in [[stage_in]],
        uint instance_id[[instance_id]],
        uint vertex_id[[vertex_id]],
        constant VertexUniforms &uniforms [[buffer(1)]],
        constant Splat *splats [[buffer(2)]],
        constant uint *splatIndices [[buffer(3)]],
        device MyCounters* my_counters [[buffer(4), function_constant(use_counters)]]
   ) {
        VertexOut out;

        if (use_counters) {
            atomic_fetch_add_explicit(&(my_counters->vertices_submitted), 1, memory_order_relaxed);
        }

        const float2 vertexModelSpacePosition = in.position.xy;
        auto splat = splats[splatIndices[instance_id]];
        const float4 splatWorldSpacePosition = uniforms.modelViewMatrix * float4(float3(splat.position), 1);
        const float4 splatClipSpacePosition = uniforms.projectionMatrix * splatWorldSpacePosition;


        const auto bounds = 1.2 * splatClipSpacePosition.w;
        if (splatClipSpacePosition.z < -splatClipSpacePosition.w
            || splatClipSpacePosition.x < -bounds
            || splatClipSpacePosition.x > bounds
            || splatClipSpacePosition.y < -bounds
            || splatClipSpacePosition.y > bounds) {
            if (use_counters) {
                atomic_fetch_add_explicit(&(my_counters->vertices_culled), 1, memory_order_relaxed);
            }
            out.position = float4(1, 1, 0, 1);
            return out;
        }


        // float3 calcCovariance2D(float3 viewPos, packed_half3 cov3Da, packed_half3 cov3Db, float4x4 viewMatrix, float4x4 projectionMatrix, float2 screenSize)
        const float3 cov2D = calcCovariance2D(splatWorldSpacePosition.xyz, splat.cov_a, splat.cov_b, uniforms.viewMatrix, uniforms.projectionMatrix, uniforms.drawableSize);
        const Tuple2<float2> axes = decomposeCovariance(cov2D);

        const float2 projectedScreenDelta = (vertexModelSpacePosition.x * axes.v0 + vertexModelSpacePosition.y * axes.v1) * 2 * kBoundsRadius / uniforms.drawableSize;
        out.position = splatClipSpacePosition + float4(projectedScreenDelta.xy * splatClipSpacePosition.w, 0, 0);
        out.relativePosition = vertexModelSpacePosition * kBoundsRadius;
        out.color = float4(splat.color);
        return out;
    }

    // MARK: -

    [[fragment]]
    float4 FragmentShader(
        FragmentIn in [[stage_in]],
        constant FragmentUniforms &uniforms [[buffer(0)]],
        constant Splat *splats [[buffer(1)]],
        constant uint *splatIndices [[buffer(3)]]
    ) {
        const auto relativePosition = in.relativePosition;
        const auto negativeDistanceSquared = -dot(relativePosition, relativePosition);
        if (negativeDistanceSquared < -kBoundsRadiusSquared) {
            discard_fragment();
        }
        const auto falloff = exp(negativeDistanceSquared);
        const auto alpha = in.color.a * falloff;
        if (alpha < uniforms.discardRate) {
            discard_fragment();
        }
        return float4(in.color.rgb * alpha, alpha);
    }
}
#endif // __METAL_VERSION__
