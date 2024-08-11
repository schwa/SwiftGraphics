#include <metal_stdlib>
#include <simd/simd.h>

#import "include/RenderKitShaders.h"

using namespace metal;

constant bool flat_shading [[function_constant(0)]];

typedef VertexIn DiffuseShadingVertexIn;

struct DiffuseShadingVertexOut {
    float4 position [[position]]; // in projection space
    float3 modelPosition;
    float3 interpolatedNormalFlat[[flat]];
    float3 interpolatedNormal;
};

typedef DiffuseShadingVertexOut DiffuseShadingFragmentIn;

struct DiffuseShadingFragmentOut {
    float4 fragmentColor [[color(0)]];
};

// MARK: -

vertex DiffuseShadingVertexOut DiffuseShadingVertexShader(
                                                          DiffuseShadingVertexIn in [[stage_in]],
    constant DiffuseShadingVertexShaderUniforms& uniforms [[buffer(1)]]
    )
{
    const float4 modelVertex = uniforms.modelViewMatrix * float4(in.position, 1.0);
    return {
        .position = uniforms.modelViewProjectionMatrix * float4(in.position, 1),
        .modelPosition = float3(modelVertex) / modelVertex.w,
        .interpolatedNormalFlat = uniforms.modelNormalMatrix * in.normal,
        .interpolatedNormal = uniforms.modelNormalMatrix * in.normal,
    };
}

fragment DiffuseShadingFragmentOut DiffuseShadingFragmentShader(DiffuseShadingFragmentIn in [[stage_in]],
    constant DiffuseShadingFragmentShaderUniforms& uniforms [[buffer(0)]],
    bool is_front_face [[front_facing]],
    uint primitive_id [[primitive_id]]
    )
{
    const float3 materialDiffuseColor = uniforms.materialDiffuseColor;
    const float3 materialAmbientColor = uniforms.materialAmbientColor;

    // Compute diffuse color
    const float3 normal = normalize(flat_shading ? in.interpolatedNormalFlat : in.interpolatedNormal);
    const float3 lightDirection = uniforms.lightPosition - in.modelPosition;
    const float3 lightDistanceSquared = length_squared(lightDirection);
    const float3 lambertian = max(dot(lightDirection, normal), 0.0);
    const float3 diffuseColor = materialDiffuseColor * lambertian * uniforms.lightDiffuseColor * uniforms.lightPower / lightDistanceSquared;

    // Compute ambient color
    const float3 ambientColor = uniforms.lightAmbientColor * materialAmbientColor;

    return {
        .fragmentColor = float4(diffuseColor + ambientColor, 1.0)
    };
}
