#pragma once

#ifdef __METAL_VERSION__
#include <metal_stdlib>
#else
#import <Foundation/Foundation.h>
#endif

#import <simd/simd.h>

struct VoxelVertex {
#ifdef __METAL_VERSION__
    half3 position [[attribute(0)]]; // 6 bytes
    half3 normal [[attribute(1)]]; // 6 bytes
    half2 textureCoordinate [[attribute(2)]]; // 4 bytes
    ushort colorIndex [[attribute(3)]]; // 2 bytes
    ushort unused [[attribute(4)]];
#else
//    simd_half3 position;
//    simd_half3 normal;
//    simd_half2 textureCoordinate;
//    unsigned short colorIndex
//    unsigned short unused;
    // tangents etc
#endif
};

// PackedVoxelVertex and VoxelVertex have to have the same structure
#ifdef __METAL_VERSION__
struct PackedVoxelVertex {
    packed_half3 position;
    packed_half3 normal;
    packed_half2 textureCoordinate;
    ushort colorIndex;
    ushort unused;
};

struct MagicaVoxel {
    uchar3 position;
    uchar color;
};
#endif
