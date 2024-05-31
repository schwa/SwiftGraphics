#include <metal_stdlib>
#import "include/RenderKitShaders.h"

using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoords;
    float4 baseColor;
    ushort instance_id;
};

typedef VertexOut FragmentIn;

struct FragmentOut {
    float4 color [[color(0)]];
};

[[vertex]]
VertexOut FlatVertexShaderInstanced(
    VertexIn vertexIn [[stage_in]],
    constant float4x4 &projectionMatrix [[buffer(1)]],
    constant Instance *instanceUniforms [[buffer(2)]],
    ushort instance_id [[instance_id]]
    )
{
    const auto uniforms = instanceUniforms[instance_id];
    const auto modelViewProjectionMatrix = projectionMatrix * uniforms.modelViewMatrix;
    VertexOut vertexOut;
    vertexOut.position = modelViewProjectionMatrix * float4(vertexIn.position, 1);
    vertexOut.texCoords = vertexIn.texCoords;
    vertexOut.baseColor = uniforms.baseColor;
    vertexOut.instance_id = instance_id;
    return vertexOut;
}

[[vertex]]
VertexOut FlatVertexShader(
    VertexIn vertexIn [[stage_in]],
    constant FlatVertexShaderUniforms &uniforms [[buffer(0)]]
    )
{
    const auto modelViewProjectionMatrix = uniforms.projectionMatrix * uniforms.modelViewMatrix;
    VertexOut vertexOut;
    vertexOut.position = modelViewProjectionMatrix * float4(vertexIn.position, 1);
    vertexOut.texCoords = vertexIn.texCoords;
    vertexOut.baseColor = uniforms.baseColor;
    return vertexOut;
}

[[fragment]]
FragmentOut FlatFragmentShader(
    FragmentIn fragmentIn [[stage_in]],
    texture2d<float, access::sample> baseColorTexture1 [[texture(0)]]
    )
{
    constexpr sampler baseColorSampler(coord::normalized, address::clamp_to_zero, filter::linear);

    const auto textureColor = baseColorTexture1.sample(baseColorSampler, fragmentIn.texCoords) * (1 - fragmentIn.baseColor[3]);
    const auto baseColor = fragmentIn.baseColor * fragmentIn.baseColor[3];

    FragmentOut result {
        .color = textureColor + baseColor,
//        .color = { 1, 0, 0, 1}
    };
    if (result.color[3] < 0.5) {
        discard_fragment();
    }
    return result;
}

[[fragment]]
ushort index_id_false_color_fragment_shader(FragmentIn fragmentIn [[stage_in]])
{
    return fragmentIn.instance_id;
}
