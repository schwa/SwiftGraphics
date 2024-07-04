#import <simd/simd.h>

#import "GaussianSplatSupport.h"

struct GaussianSplatUniforms {
    simd_float4x4 modelViewProjectionMatrix;
    simd_float4x4 modelViewMatrix;
    simd_float4x4 projectionMatrix;
    simd_float4x4 modelMatrix;
    simd_float4x4 viewMatrix;
    simd_float4x4 cameraMatrix;
    simd_float3 cameraPosition;
    simd_float2 drawableSize;
};

struct GaussianSplatSortUniforms {
    unsigned int splatCount;
    unsigned int groupWidth;
    unsigned int groupHeight;
    unsigned int stepIndex;
};

#ifdef __METAL_VERSION__
#import <metal_stdlib>

namespace GaussianSplatShaders {

    using namespace metal;

    struct VertexIn {
        float3 position  [[attribute(0)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float2 relativePosition; // Ranges from -kBoundsRadius to +kBoundsRadius
        float4 color;
    };

    struct SplatC {
        packed_half3 position;
        packed_half4 color;
        packed_half3 cov_a;
        packed_half3 cov_b;
    };

    typedef SplatC Splat;

    typedef GaussianSplatUniforms VertexUniforms;
    typedef GaussianSplatUniforms FragmentUniforms;
    typedef VertexOut FragmentIn;

    struct FragmentOut {
        float4 fragColor [[color(0)]];
    };

    // MARK: -


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
        constant uint *splatIndices [[buffer(3)]]
   ) {
        VertexOut out;

        const float2 vertexModelSpacePosition = in.position.xy;
        auto splat = splats[splatIndices[instance_id]];
        const float4 splatWorldSpacePosition = uniforms.modelViewMatrix * float4(float3(splat.position), 1);
        const float4 splatClipSpacePosition = uniforms.projectionMatrix * splatWorldSpacePosition;

//        const auto bounds = 1.2 * splatClipSpacePosition.w;
//        if (splatClipSpacePosition.z < -splatClipSpacePosition.w
//            || splatClipSpacePosition.x < -bounds
//            || splatClipSpacePosition.x > bounds
//            || splatClipSpacePosition.y < -bounds
//            || splatClipSpacePosition.y > bounds) {
//            out.position = float4(1, 1, 0, 1);
//            return out;
//        }

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
        return float4(in.color.rgb * alpha, alpha);
    }

    // MARK: -

    [[kernel]]
    void DistancePreCalc(
        uint3 thread_position_in_grid [[thread_position_in_grid]],
        constant simd_float3x3 &modelMatrix[[buffer(0)]],
        constant simd_float3 &cameraPosition[[buffer(1)]],
        constant Splat *splats [[buffer(2)]],
        constant uint &splatCount [[buffer(3)]],
        device float *splatDistances [[buffer(4)]]
    ) {
        const uint index = thread_position_in_grid.x;
        if (index >= splatCount) {
            return;
        }
        const auto position = modelMatrix * float3(splats[index].position);
        const auto distance = distance_squared(position, cameraPosition);
        splatDistances[index] = distance;
    }

    // MARK: -

    [[kernel]]
    void BitonicSortSplats(
        uint3 thread_position_in_grid [[thread_position_in_grid]],
        constant GaussianSplatSortUniforms &uniforms [[buffer(0)]],
        constant float *splatDistances [[buffer(1)]],
        device uint *splatIndices [[buffer(2)]]
    ) {
        const auto index = thread_position_in_grid.x;
        const auto hIndex = index & (uniforms.groupWidth - 1);
        const auto indexLeft = hIndex + (uniforms.groupHeight + 1) * (index / uniforms.groupWidth);
        const auto stepSize = uniforms.stepIndex == 0 ? uniforms.groupHeight - 2 * hIndex : (uniforms.groupHeight + 1) / 2;
        const auto indexRight = indexLeft + stepSize;
        // Exit if out of bounds (for non-power of 2 input sizes)
        if (indexRight >= uniforms.splatCount) {
            return;
        }

        const auto valueLeft = splatIndices[indexLeft];
        const auto valueRight = splatIndices[indexRight];
        auto distanceLeft = splatDistances[valueLeft];
        auto distanceRight = splatDistances[valueRight];
        // Swap entries if value is descending
        if (distanceLeft < distanceRight) {
            // TODO: Does metal have a swap function?
            splatIndices[indexLeft] = valueRight;
            splatIndices[indexRight] = valueLeft;
        }
    }
}
#endif // __METAL_VERSION__
