#pragma once

#import <simd/simd.h>

struct Particle {
    simd_float3 position;
    simd_float3 oldPosition;
    simd_float3 acceleration;
    float age;
    float lifetime;
};

struct ParticlesEnvironment {
    simd_float3 gravity;
    float timestep;
};
