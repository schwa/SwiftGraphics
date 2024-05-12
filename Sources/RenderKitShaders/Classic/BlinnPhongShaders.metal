#include <metal_stdlib>
#include <simd/simd.h>

#include "include/BlinnPhongShaders.h"
#include "include/Support.h"
#include "include/Shaders.h"

// https://en.wikipedia.org/wiki/Blinn–Phong_reflection_model

using namespace metal;

// MARK: Constants

constant int kPhongMode [[ function_constant(BlinnPhongBindings_BlinnPhongModeConstant)]];

// MARK: Types

struct Fragment {
    float4 position [[position]]; // in projection space
    float3 modelPosition;
    float3 interpolatedNormal;
    float2 textureCoordinate;
};

// MARK: Shader Functions

[[vertex]]
Fragment BlinnPhongVertexShader(Vertex in [[stage_in]],
                                constant Transforms &transforms [[buffer(CommonBindings_TransformsBuffer)]])
{
    Fragment out;
    const float4 modelVertex = transforms.modelView * float4(in.position, 1.0);
    out.position = transforms.projection * modelVertex;
    out.modelPosition = float3(modelVertex) / modelVertex.w;
    out.interpolatedNormal = transforms.modelNormal * in.normal;
    out.textureCoordinate = in.textureCoordinate;
    return out;
}

[[fragment]]
float4 BlinnPhongFragmentShader(Fragment in [[stage_in]],
                                constant BlinnPhongLightingModelArgumentBuffer &lightingModel [[buffer(BlinnPhongBindings_LightingModelArgumentBuffer)]],
                                constant BlinnPhongMaterialArgumentBuffer &material [[buffer(BlinnPhongBindings_MaterialArgumentBuffer)]]
                                )
{
    float3 ambientColor = material.ambientTexture.sample(material.ambientSampler, in.textureCoordinate).rgb;
    float3 diffuseColor = material.diffuseTexture.sample(material.diffuseSampler, in.textureCoordinate).rgb;
    float3 specularColor = material.specularTexture.sample(material.specularSampler, in.textureCoordinate).rgb;
    float3 color = CalculateBlinnPhong(in.modelPosition, in.interpolatedNormal, lightingModel, material.shininess, ambientColor, diffuseColor, specularColor);
    return float4(GammaCorrect(color, lightingModel.screenGamma), 1.0);
}

// MARK: Helper Functions


float3 CalculateBlinnPhong(float3 modelPosition,
                           float3 interpolatedNormal,
                           constant BlinnPhongLightingModelArgumentBuffer &lightingModel,
                           float shininess,
                           float3 ambientColor,
                           float3 diffuseColor,
                           float3 specularColor
                           )
{

    float3 accumulatedDiffuseColor = { 0, 0, 0 };
    float3 accumulatedSpecularColor = { 0, 0, 0 };

    for (int index = 0; index != lightingModel.lightCount; ++index) {
        const auto light = lightingModel.lights[index];
        const float3 normal = normalize(interpolatedNormal);
        float3 lightDir = lightingModel.lights[index].lightPosition - modelPosition;
        float distance = length(lightDir);
        distance = distance * distance;
        lightDir = normalize(lightDir);

        const float lambertian = max(dot(lightDir, normal), 0.0);
        float specular = 0.0;

        if (lambertian > 0.0)
        {
            const float3 viewDir = normalize(-modelPosition);
            // this is blinn phong
            if (kPhongMode == 0)
            {
                const float3 halfDir = normalize(lightDir + viewDir);
                const float specularAngle = max(dot(halfDir, normal), 0.0);
                specular = pow(specularAngle, shininess);
            }
            else
            {
                // this is phong (for comparison)
                const float3 reflectDir = reflect(-lightDir, normal);
                const float specularAngle = max(dot(reflectDir, viewDir), 0.0);
                // note that the exponent is different here
                specular = pow(specularAngle, shininess / 4.0);
            }
        }
        accumulatedDiffuseColor += diffuseColor * lambertian * light.lightColor * light.lightPower / distance;
        accumulatedSpecularColor += specularColor * specular * light.lightColor * light.lightPower / distance;
    }

    float3 finalColor = lightingModel.ambientLightColor * ambientColor + accumulatedDiffuseColor + accumulatedSpecularColor;
    return finalColor;
}
