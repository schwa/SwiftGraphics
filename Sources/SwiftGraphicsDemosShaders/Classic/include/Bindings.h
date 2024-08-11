#pragma once

#include "Common.h"

typedef NS_ENUM(NSInteger, CommonBindings) {
    CommonBindings_VerticesBuffer = 0,
    CommonBindings_FrameStateBuffer = 1,
    CommonBindings_TransformsBuffer = 2,
};

typedef NS_ENUM(NSInteger, SamplerBindings) {
    UnlitBaseColorSamplerIndex = 3
};

typedef NS_ENUM(NSInteger, BlinnPhongBindings) {
    BlinnPhongBindings_LightingModelArgumentBuffer = 4,
    BlinnPhongBindings_MaterialArgumentBuffer = 5,
    BlinnPhongBindings_BlinnPhongModeConstant = 6
};

typedef NS_ENUM(NSInteger, UnlitShaderBindings) {
    UnlitShaderBindings_BaseColorTexture = 7,
    UnlitShaderBindings_BaseColorSampler = 8,
    UnlitShaderBindings_OffsetsBuffer = 9,
};

typedef NS_ENUM(NSInteger, CheckerBoardComputeBindings) {
    CheckerBoardComputeBindings_OutputTexture = 10,
    CheckerBoardComputeBindings_SizeBuffer = 11,
};

typedef NS_ENUM(NSInteger, VoronoiNoiseComputeBindings) {
    VoronoiNoiseComputeBindings_OutputTexture = 12,
    VoronoiNoiseComputeBindings_OffsetBuffer = 13,
    VoronoiNoiseComputeBindings_SizeBuffer = 14,
    VoronoiNoiseComputeBindings_ModeBuffer = 15,
};


typedef NS_ENUM(NSInteger, SimplexNoise2DBindings) {
    SimplexNoise2DBindings_OutputTexture = 16,
};


typedef NS_ENUM(NSInteger, GPULifeKernelBindings) {
    GPULifeKernelBindings_InputTexture = 17,
    GPULifeKernelBindings_OutputTexture = 18,
};


typedef NS_ENUM(NSInteger, VoxelsBindings) {
    VoxelsBindings_VoxelsBuffer = 19,
    VoxelsBindings_ColorPaletteTexture = 20,
    VoxelsBindings_OutputTexture = 21,
    VoxelsBindings_VoxelSizeBuffer = 22,
    VoxelsBindings_VerticesBuffer = 23,
    VoxelsBindings_IndicesBuffer = 24,
    VoxelsBindings_BlinnPhongLightingModelArgumentBuffer = BlinnPhongBindings_LightingModelArgumentBuffer,
};

typedef NS_ENUM(NSInteger, DebugShaderBindings) {
    DebugShaderBindings_ModeBuffer = 25,
};

typedef NS_ENUM(NSInteger, ParticleShadersBindings) {
    ParticleShadersBindings_EnvironmentBuffer = 26,
    ParticleShadersBindings_ParticlesBuffer = 27,
};
