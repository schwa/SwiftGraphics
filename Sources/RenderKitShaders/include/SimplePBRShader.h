struct ArgumentBufferExample {
    TEXTURE2D(float, access::write) a;
    SAMPLER c;
    TEXTURE2D(float) d;
    DEVICE_PTR(float) e;
    TEXTURE2D(float) f;
    int g;
//    SimplePBRMaterial material;
};

struct SimplePBRMaterial {
    simd_float3 baseColor;
    float metallic;
    float roughness;
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
namespace SimplePBRShader {

    using namespace metal;

    struct VertexIn {
        float3 position [[attribute(0)]];
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

    [[vertex]]
    VertexOut VertexShader(
        VertexIn in [[stage_in]],
        constant VertexUniforms &uniforms[[buffer(1)]]
    ) {
        VertexOut out;
        out.position = uniforms.modelViewProjectionMatrix * float4(in.position, 1.0);
        out.worldPosition = (uniforms.modelMatrix * float4(in.position, 1.0)).xyz;
        out.worldNormal = normalize((uniforms.modelMatrix * float4(in.normal, 1.0)).xyz);
        out.uv = in.uv;
        return out;
    }

    float D_GGX(float NoH, float a) {
        float a2 = a * a;
        float f = (NoH * a2 - NoH) * NoH + 1.0;
        return a2 / (M_PI_F * f * f);
    }

    float3 F_Schlick(float u, float3 f0) {
        return f0 + (float3(1.0) - f0) * pow(1.0 - u, 5.0);
    }

    float V_SmithGGXCorrelated(float NoV, float NoL, float a) {
        float a2 = a * a;
        float GGXL = NoV * sqrt((-NoL * a2 + NoL) * NoL + a2);
        float GGXV = NoL * sqrt((-NoV * a2 + NoV) * NoV + a2);
        return 0.5 / (GGXV + GGXL);
    }

    float V_SmithGGXCorrelatedFast(float NoV, float NoL, float roughness) {
        float a = roughness;
        float GGXV = NoL * (NoV * (1.0 - a) + a);
        float GGXL = NoV * (NoL * (1.0 - a) + a);
        return 0.5 / (GGXV + GGXL);
    }

    float Fd_Lambert() {
        return 1.0 / M_PI_F;
    }

    float F_Schlick(float u, float f0, float f90) {
        return f0 + (f90 - f0) * pow(1.0 - u, 5.0);
    }

    float Fd_Burley(float NoV, float NoL, float LoH, float roughness) {
        float f90 = 0.5 + 2.0 * roughness * LoH * LoH;
        float lightScatter = F_Schlick(NoL, 1.0, f90);
        float viewScatter = F_Schlick(NoV, 1.0, f90);
        return lightScatter * viewScatter * (1.0 / M_PI_F);
    }

    float3 brdf(thread const FragmentIn &in, thread const FragmentUniforms uniforms, thread const Material material, thread const Light light) {
        // Specular term: a Cook-Torrance specular microfacet model, with a GGX normal distribution function, a Smith-GGX height-correlated visibility function, and a Schlick Fresnel function.
        // Diffuse term: a Lambertian diffuse model OR Disney diffus

        float3 l = normalize(light.position - in.worldPosition);
        float3 n = in.worldNormal;
        float3 v = normalize(uniforms.cameraPosition - in.worldPosition);
        float perceptualRoughness = material.roughness;
        float3 f0 = material.baseColor;
        float3 diffuseColor = (1.0 - material.metallic) * material.baseColor.rgb;

        float3 h = normalize(v + l);
        float NoV = abs(dot(n, v)) + 1e-5;
        float NoL = clamp(dot(n, l), 0.0, 1.0);
        float NoH = clamp(dot(n, h), 0.0, 1.0);
        float LoH = clamp(dot(l, h), 0.0, 1.0);

        // perceptually linear roughness to roughness (see parameterization)
        float roughness = perceptualRoughness * perceptualRoughness;

        // Normal distribution function (specular D)
        float D = D_GGX(NoH, roughness);

        // Fresnel (specular F)
        float3  F = F_Schlick(LoH, f0);

        // (Visibility V)
        float V = V_SmithGGXCorrelated(NoV, NoL, roughness);

        // specular BRDF
        float3 Fr = (D * V) * F;

        // diffuse BRDF
//        float3 Fd = diffuseColor * Fd_Lambert();
        float3 Fd = diffuseColor * Fd_Burley(NoV, NoL, LoH, perceptualRoughness);

        return Fr + Fd;
    }

    [[fragment]]
    float4 FragmentShader(
        FragmentIn in [[stage_in]],
        constant SimplePBRFragmentUniforms &uniforms [[buffer(0)]],
        constant Material& material [[buffer(1)]],
        constant Light& light [[buffer(2)]]
    ) {
        return float4(brdf(in, uniforms, material, light), 1.0);
    }
}

#endif // __METAL_VERSION__
