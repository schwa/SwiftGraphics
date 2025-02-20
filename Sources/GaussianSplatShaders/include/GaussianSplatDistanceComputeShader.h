#import <simd/simd.h>

#import "GaussianSplatSupport.h"

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
        device IndexedDistance *indexedDistances [[buffer(4)]]
    ) {
        const uint index = thread_position_in_grid.x;
        if (index >= splatCount) {
            return;
        }
        const auto position = modelMatrix * float3(splats[index].position);
        const auto distance = distance_squared(position, cameraPosition);
        indexedDistances[index].index = index;
        indexedDistances[index].distanceToCamera = distance;
    }
}
#endif // __METAL_VERSION__
