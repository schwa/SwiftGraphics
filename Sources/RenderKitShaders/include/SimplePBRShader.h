#include <simd/simd.h>

struct SimplePBRMaterial {
    simd_float3 albedo;
    float metallic;
    float roughness;
    simd_float3 ambientOcclusion;
};

struct SimplePBRLight {
    simd_float3 position;
    simd_float3 color;
    float intensity;
};

struct SimplePBRVertexUniforms {
    simd_float4x4 modelViewProjectionMatrix;
    simd_float4x4 modelMatrix;
};

struct SimplePBRFragmentUniforms {
    simd_float3 cameraPosition;
};

#ifdef __METAL_VERSION__
#include <metal_stdlib>
#include <metal_math>

namespace SimplePBRShader {

    using namespace metal;

    struct VertexIn {
        float4 position [[attribute(0)]];
        float3 normal [[attribute(1)]];
        float2 uv [[attribute(2)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float3 worldPosition;
        float3 worldNormal;
        float2 uv;
    };

    typedef SimplePBRMaterial Material;
    typedef SimplePBRLight Light;
    typedef SimplePBRVertexUniforms VertexUniforms;
    typedef SimplePBRFragmentUniforms FragmentUniforms;
    typedef VertexOut FragmentIn;

    float DistributionGGX(float3 N, float3 H, float roughness) {
        float a = roughness * roughness;
        float a2 = a * a;
        float NdotH = max(dot(N, H), 0.0);
        float NdotH2 = NdotH * NdotH;

        float num = a2;
        float denom = (NdotH2 * (a2 - 1.0) + 1.0);
        denom = M_PI_F * denom * denom;

        return num / denom;
    }

    float GeometrySchlickGGX(float NdotV, float roughness) {
        float r = (roughness + 1.0);
        float k = (r * r) / 8.0;

        float num = NdotV;
        float denom = NdotV * (1.0 - k) + k;

        return num / denom;
    }

    float GeometrySmith(float3 N, float3 V, float3 L, float roughness) {
        float NdotV = max(dot(N, V), 0.0);
        float NdotL = max(dot(N, L), 0.0);
        float ggx1 = GeometrySchlickGGX(NdotV, roughness);
        float ggx2 = GeometrySchlickGGX(NdotL, roughness);
        return ggx1 * ggx2;
    }

    float3 FresnelSchlick(float cosTheta, float3 F0) {
        return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
    }

    [[vertex]]
    VertexOut VertexShader(
        VertexIn in [[stage_in]],
        constant VertexUniforms &uniforms[[buffer(1)]]
    ) {
        VertexOut out;
        out.position = uniforms.modelViewProjectionMatrix * in.position;
        out.worldPosition = (uniforms.modelMatrix * in.position).xyz;
        out.worldNormal = normalize((uniforms.modelMatrix * float4(in.normal, 0.0)).xyz);
        out.uv = in.uv;
        return out;
    }

    [[fragment]]
    float4 FragmentShader(
        FragmentIn in [[stage_in]],
        constant SimplePBRFragmentUniforms &uniforms [[buffer(0)]],
        constant Material& material [[buffer(1)]],
        constant Light& light [[buffer(2)]]
//        texture2d<float> albedoMap [[texture(0)]],
//        sampler textureSampler [[sampler(0)]]
    ) {

//        float3 albedo = material.albedo * albedoMap.sample(textureSampler, in.uv).rgb;
        float3 albedo = material.albedo;
        float3 N = normalize(in.worldNormal);
        float3 V = normalize(uniforms.cameraPosition - in.worldPosition);
        float3 L = normalize(light.position - in.worldPosition);
        float3 H = normalize(V + L);
        float3 radiance = light.color * light.intensity;

        float NDF = DistributionGGX(N, H, material.roughness);
        float G = GeometrySmith(N, V, L, material.roughness);
        float3 F0 = mix(float3(0.04), albedo, material.metallic);
        float3 F = FresnelSchlick(max(dot(H, V), 0.0), F0);
        float3 kS = F;
        float3 kD = float3(1.0) - kS;
        kD *= 1.0 - material.metallic;

        float NdotL = max(dot(N, L), 0.0);
        float3 numerator = NDF * G * F;
        float denominator = 4.0 * max(dot(N, V), 0.0) * NdotL + 0.001;
        float3 specular = numerator / denominator;

        float3 ambient = material.ambientOcclusion * albedo;
        float3 color = ambient + (kD * albedo / M_PI_F + specular) * radiance * NdotL;

        return float4(color, 1.0);
    }
}

#endif // __METAL_VERSION__
