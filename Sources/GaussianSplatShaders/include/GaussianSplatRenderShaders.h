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
        half4 color;
    };

    typedef GaussianSplatUniforms VertexUniforms;
    typedef GaussianSplatUniforms FragmentUniforms;
    typedef VertexOut FragmentIn;

    // MARK: -

    constant static const float kBoundsRadius = 2;
    constant static const float kBoundsRadiusSquared = kBoundsRadius * kBoundsRadius;

    float3x3 convert(const float4x4 m) {
        return float3x3(m[0].xyz, m[1].xyz, m[2].xyz);
    }

    bool isOutOfBounds(const float4 v, const float bounds) {
        return v.z < -v.w || v.x < -bounds || v.x > bounds || v.y < -bounds || v.y > bounds;
    }

    [[vertex]]
    VertexOut VertexShader(
        VertexIn in [[stage_in]],
        uint instance_id[[instance_id]],
        uint vertex_id[[vertex_id]],
        constant VertexUniforms &uniforms [[buffer(1)]],
        constant SplatC *splats [[buffer(2)]],
        constant IndexedDistance *indexedDistances [[buffer(3)]],
        device MyCounters* my_counters [[buffer(4), function_constant(use_counters)]]
   ) {
   // Uniforms
//    simd_float4x4 modelViewProjectionMatrix; // NOT USED
//    simd_float4x4 modelViewMatrix;           // USED
//    simd_float4x4 projectionMatrix;          // USED
//    simd_float4x4 viewMatrix;                // USED
//    simd_float4x4 modelMatrix;                // ?
//    simd_float3x3 inverseModelRotationMatrix;
//    simd_float3 cameraPosition;              // NOT USED
//    simd_float2 drawableSize;                // USED
//    float discardRate;                       // USED (VS ONLY)

        VertexOut out;

        if (use_counters) {
            atomic_fetch_add_explicit(&(my_counters->vertices_submitted), 1, memory_order_relaxed);
        }

        auto indexedDistance = indexedDistances[instance_id];
        auto splat = splats[indexedDistance.index];
        const float4 splatWorldSpacePosition = uniforms.viewMatrix * float4(float3(splat.position), 1);
        const float4 splatClipSpacePosition = uniforms.projectionMatrix * splatWorldSpacePosition;

        if (isOutOfBounds(splatClipSpacePosition, 1.2 * splatClipSpacePosition.w)) {
            if (use_counters) {
                atomic_fetch_add_explicit(&(my_counters->vertices_culled), 1, memory_order_relaxed);
            }
            out.position = float4(1, 1, 0, 1);
            return out;
        }

        const float3 covPosition = splatWorldSpacePosition.xyz;
        const Tuple2<float2> axes = decomposeDalcCovariance2D(covPosition, splat.cov_a, splat.cov_b, uniforms.viewMatrix, uniforms.projectionMatrix, uniforms.drawableSize);

        const float2 vertexModelSpacePosition = in.position.xy;
        const float2 projectedScreenDelta = (vertexModelSpacePosition.x * axes.v0 + vertexModelSpacePosition.y * axes.v1) * 2 * kBoundsRadius / uniforms.drawableSize * splatClipSpacePosition.w;
        out.position = splatClipSpacePosition + float4(projectedScreenDelta, 0, 0);
        out.relativePosition = vertexModelSpacePosition * kBoundsRadius;
        out.color = splat.color;
        return out;
    }

    // MARK: -

    [[fragment]]
    half4 FragmentShader(
        FragmentIn in [[stage_in]],
        constant FragmentUniforms &uniforms [[buffer(0)]]
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
        return half4(in.color.rgb * alpha, alpha);
    }
}
#endif // __METAL_VERSION__
