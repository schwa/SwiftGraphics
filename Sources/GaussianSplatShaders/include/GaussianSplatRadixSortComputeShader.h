#import <simd/simd.h>

#import "GaussianSplatSupport.h"

//struct GaussianSplatSortUniforms {
//    unsigned int splatCount;
//    unsigned int groupWidth;
//    unsigned int groupHeight;
//    unsigned int stepIndex;
//};

#ifdef __METAL_VERSION__
#import <metal_stdlib>

namespace GaussianSplatShaders {
    using namespace metal;

    [[kernel]]
    void histogram(device const uint* input [[buffer(0)]],
                          device atomic_uint* histogram [[buffer(1)]],
                          constant uint& pass [[buffer(2)]],
                          uint id [[thread_position_in_grid]],
                          uint threadcount [[threads_per_grid]]) {
        for (uint i = id; i < threadcount; i += threadcount) {
            uint value = input[i];
            uint bucket = (value >> (pass * 8)) & 0xFF;
            atomic_fetch_add_explicit(&histogram[bucket], 1, memory_order_relaxed);
        }
    }

    [[kernel]]
    void scan(device atomic_uint* histogram [[buffer(0)]]) {
        uint sum = 0;
        for (uint i = 0; i < 256; i++) {
            uint count = atomic_load_explicit(&histogram[i], memory_order_relaxed);
            atomic_store_explicit(&histogram[i], sum, memory_order_relaxed);
            sum += count;
        }
    }

    [[kernel]]
    void scatter(device const uint* input [[buffer(0)]],
                        device uint* output [[buffer(1)]],
                        device const atomic_uint* histogram [[buffer(2)]],
                        constant uint& pass [[buffer(3)]],
                        uint id [[thread_position_in_grid]],
                        uint threadcount [[threads_per_grid]]) {
        for (uint i = id; i < threadcount; i += threadcount) {
            uint value = input[i];
            uint bucket = (value >> (pass * 8)) & 0xFF;
            uint index = atomic_fetch_add_explicit((device atomic_uint*)&histogram[bucket], 1, memory_order_relaxed);
            output[index] = value;
        }
    }
}
#endif // __METAL_VERSION__
