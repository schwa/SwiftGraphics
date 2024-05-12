#include <metal_stdlib>
#include "include/Shaders.h"
#include "include/ParticleShaders.h"
#include "include/Random.h"

using namespace metal;

float3 apply_forces(float3 vel, float drag, float mass)
{
    float3 grav_acc = float3{0.0, -9.81, 0 }; // 9.81m/s^2 down in the Z-axis
    float3 drag_force = 0.5 * drag * (vel * abs(vel)); // D = 0.5 * (rho * C * Area * vel^2)
    float3 drag_acc = drag_force / mass; // a = F/m
    return grav_acc - drag_acc;
}

// MARK: -

[[kernel]]
void particleUpdate(
                    uint gid [[thread_position_in_grid]],
                    device Particle *particles[[buffer(ParticleShadersBindings_ParticlesBuffer)]],
                    constant ParticlesEnvironment &environment [[buffer(ParticleShadersBindings_EnvironmentBuffer)]]
                    )
{
    auto particle = particles[gid];
    if (particle.age >= particle.lifetime || particle.position.y < 0) {
        particle.age = 0;
        particle.position = float3(0, 0, 0);
        particle.oldPosition = float3(0, 0, 0);
        particle.acceleration = (rand1dTo3d(gid) + float3(-0.5, 0, -0.5)) * float3(200, 2000, 200);
    }
    const auto temp = particle.position;
    const float timestep = environment.timestep;
    particle.position += particle.position - particle.oldPosition + particle.acceleration * timestep * timestep;
    particle.oldPosition = temp;
    particle.age += timestep;
    particle.acceleration = apply_forces(particle.position - particle.oldPosition, 0.1, 1);
    particles[gid] = particle;
}

// MARK: -

struct Fragment
{
    float4 position [[position]];
    float2 textureCoordinate;
    uint particle_id;
};

[[vertex]]
Fragment classicParticleVertexShader(
                              Vertex in [[stage_in]],
                              constant Transforms &transforms [[buffer(CommonBindings_TransformsBuffer)]],
                              device const Particle *particles[[buffer(ParticleShadersBindings_ParticlesBuffer)]],
                              uint iid [[instance_id]])
{
    const auto particle = particles[iid];
    Fragment out;
    out.position = transforms.projection * transforms.modelView * float4(in.position + particle.position, 1.0);
    out.textureCoordinate = in.textureCoordinate;
    out.particle_id = iid;
    return out;
}

[[fragment]]
float4 classicParticleFragmentShader(
                              Fragment in [[stage_in]],
                              device const Particle *particles[[buffer(ParticleShadersBindings_ParticlesBuffer)]]
                              )
{
    const auto particle = particles[in.particle_id];
    if (particle.age >= particle.lifetime) {
        discard_fragment();
    }
    return float4(1, 0, 1, 1) * 1 - (particle.age / particle.lifetime);
}
