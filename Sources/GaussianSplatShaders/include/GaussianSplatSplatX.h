#import <simd/simd.h>

struct SplatX {
    simd_float3 position; // 12
    // padding // 4
    simd_half2 u1; // 4
    simd_half2 u2; // 4
    simd_half2 u3; // 4
    simd_uchar4 color; // 4
};
