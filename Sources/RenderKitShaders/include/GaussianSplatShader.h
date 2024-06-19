#include <simd/simd.h>

struct GaussianSplatUniforms {
    simd_float4x4 modelViewProjectionMatrix;
    simd_float4x4 modelMatrix;
    simd_float3 cameraPosition;
};

struct GaussianSplatSortUniforms {
    unsigned int splatCount;
    unsigned int groupWidth;
    unsigned int groupHeight;
    unsigned int stepIndex;
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

    [[vertex]]
    VertexOut VertexShader(
        VertexIn in [[stage_in]],
        uint instance_id[[instance_id]],
        constant VertexUniforms &uniforms [[buffer(1)]],
        constant Splat *splats [[buffer(2)]],
        constant uint *splatIndices [[buffer(3)]]
   ) {
        auto splat = splats[splatIndices[instance_id]];
        auto position = uniforms.modelViewProjectionMatrix * float4(float3(splat.position) + in.position, 1.0);
        return {
            .position = position,
            .instance_id = instance_id,
        };
    }

    [[fragment]]
    float4 FragmentShader(
        FragmentIn in [[stage_in]],
        constant FragmentUniforms &uniforms [[buffer(0)]],
        constant Splat *splats [[buffer(1)]],
        constant uint *splatIndices [[buffer(3)]]
    ) {
        auto splat = splats[splatIndices[in.instance_id]];
        if (false) {
            auto color = float4(splat.color);
            return color;
        }
        else {
            auto d = 1 - distance((uniforms.modelMatrix * float4(float3(splat.position), 1)).xyz, uniforms.cameraPosition) / 4;
            //auto d = float(in.instance_id) / 1026508.0;
            return float4(d, d, d, 1);
        }
    }


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
        if (distanceLeft > distanceRight) {
            // TODO: Does metal have a swap function?
            splatIndices[indexLeft] = valueRight;
            splatIndices[indexRight] = valueLeft;
        }
    }
}
#endif
