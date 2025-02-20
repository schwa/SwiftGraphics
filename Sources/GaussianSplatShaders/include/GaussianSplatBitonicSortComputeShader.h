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
    void BitonicSortSplats(
        uint3 thread_position_in_grid [[thread_position_in_grid]],
        constant GaussianSplatSortUniforms &uniforms [[buffer(0)]],
        device IndexedDistance *indexedDistances [[buffer(1)]]
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

        const auto valueLeft = indexedDistances[indexLeft];
        const auto valueRight = indexedDistances[indexRight];
        auto distanceLeft = valueLeft.distanceToCamera;
        auto distanceRight = valueRight.distanceToCamera;
        // Swap entries if value is descending
        if (distanceLeft < distanceRight) {
            // TODO: Does metal have a swap function?
            indexedDistances[indexLeft] = valueRight;
            indexedDistances[indexRight] = valueLeft;
        }
    }
}
#endif // __METAL_VERSION__
