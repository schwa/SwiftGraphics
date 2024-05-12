#import "include/RenderKitShaders.h"
#import "include/FlatShader.h"

typedef SimpleVertex Vertex;

struct Fragment {
    float4 position [[position]]; // in projection space
    float3 modelPosition;
    float3 interpolatedNormalFlat[[flat]];
    float3 interpolatedNormal;
    float2 textureCoordinate;
    ushort instance_id[[flat]];
};

// MARK: -

[[vertex]]
Fragment flatShaderVertexShader(
    Vertex in [[stage_in]],
    ushort instance_id[[instance_id]],
    constant CameraUniforms &camera [[buffer(1)]],
    constant ModelTransforms *modelTransforms [[buffer(2)]]
    )
{
    const ModelTransforms modelTransform = modelTransforms[instance_id];
    const float4 modelVertex = modelTransform.modelViewMatrix * float4(in.position, 1.0);
    return {
        .position = camera.projectionMatrix * modelVertex,
        .modelPosition = float3(modelVertex) / modelVertex.w,
        .interpolatedNormalFlat = modelTransform.modelNormalMatrix * in.normal,
        .interpolatedNormal = modelTransform.modelNormalMatrix * in.normal,
        .textureCoordinate = in.textureCoordinate,
        .instance_id = instance_id
    };
}

[[fragment]]
vector_float4 flatShaderFragmentShader(
    Fragment in [[stage_in]],
    constant LightUniforms &lighting [[buffer(1)]],
    constant FlatMaterial *materials [[buffer(2)]],
    array<texture2d<float, access::sample>, 128> textures [[texture(0)]]
)
{
    auto material = materials[in.instance_id];
    const auto diffuseMaterialColor = material.diffuseColor.xyz;
    const auto ambientMaterialColor= material.ambientColor.xyz;

    // Compute diffuse color
    const auto normal = normalize(in.interpolatedNormalFlat);
    const auto lightDirection = lighting.lightPosition - in.modelPosition;
    const auto lightDistanceSquared = length_squared(lightDirection);
    const auto lambertian = max(dot(lightDirection, normal), 0.0);
    const auto diffuseColor = diffuseMaterialColor * lambertian * lighting.lightColor * lighting.lightPower / lightDistanceSquared;

    // Compute ambient color
    const auto ambientColor = lighting.ambientLightColor * ambientMaterialColor;

    return float4(diffuseColor + ambientColor, 1.0);
}

// https://en.wikipedia.org/wiki/Blinn–Phong_reflection_model
