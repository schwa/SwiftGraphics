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
    simd_float3x3 modelMatrix;
    simd_float3 cameraPosition;
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
        auto position = uniforms.modelViewProjectionMatrix * float4(splat.position + in.position, 1.0);
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
        auto color = float4(splat.color) / 255.0;
        return color;
//        auto d = 1 - distance((uniforms.modelMatrix * float4(splat.position, 1)).xyz, uniforms.cameraPosition) / 4;
//        auto d = float(in.instance_id) / 1026508.0;
//        return float4(d, d, d, 1);
    }

    [[kernel]]
    void BitonicSortSplats(
        uint3 thread_position_in_grid [[thread_position_in_grid]],
        constant GaussianSplatSortUniforms &uniforms [[buffer(0)]],
        device Splat *splats [[buffer(1)]],
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
        const auto splatLeft = splats[valueLeft];
        const auto splatRight = splats[valueRight];

        // TODO: Waste of two sqrts() here.
        auto distanceLeft = distance(uniforms.modelMatrix * float3(splatLeft.position), uniforms.cameraPosition);
        auto distanceRight = distance(uniforms.modelMatrix * float3(splatRight.position), uniforms.cameraPosition);

        // Swap entries if value is descending
        if (distanceLeft > distanceRight) {
            // TODO: Does metal have a swap function?
            splatIndices[indexLeft] = valueRight;
            splatIndices[indexRight] = valueLeft;
        }
    }
}

[[kernel]]
void bitonicSort(
    uint3 thread_position_in_grid [[thread_position_in_grid]],
    constant uint &numEntries [[buffer(0)]],
    constant uint &groupWidth [[buffer(1)]],
    constant uint &groupHeight [[buffer(2)]],
    constant uint &stepIndex [[buffer(3)]],
    device uint *entries [[buffer(4)]]
) {
    const auto index = thread_position_in_grid.x;
    const auto hIndex = index & (groupWidth - 1);
    const auto indexLeft = hIndex + (groupHeight + 1) * (index / groupWidth);
    const auto stepSize = stepIndex == 0 ? groupHeight - 2 * hIndex : (groupHeight + 1) / 2;
    const auto indexRight = indexLeft + stepSize;
    // Exit if out of bounds (for non-power of 2 input sizes)
    if (indexRight >= numEntries) {
        return;
    }
    const auto valueLeft = entries[indexLeft];
    const auto valueRight = entries[indexRight];
    // Swap entries if value is descending
    if (valueLeft > valueRight) {
        entries[indexLeft] = valueRight;
        entries[indexRight] = valueLeft;
    }
}


#endif
