#import <simd/simd.h>

#import "GaussianSplatSupport.h"

struct GaussianSplatSortUniforms {
    unsigned int splatCount;
    unsigned int groupWidth;
    unsigned int groupHeight;
    unsigned int stepIndex;
};

#ifdef __METAL_VERSION__
#import <metal_stdlib>

namespace GaussianSplatShaders {

    typedef SplatC Splat;

    using namespace metal;

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
