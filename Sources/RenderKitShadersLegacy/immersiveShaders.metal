#import "include/RenderKitShaders.h"

using namespace metal;

typedef struct
{
    float3 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
} VertexOut;

typedef VertexOut ShaderIn;

vertex VertexOut vertexShader(
    Vertex in [[stage_in]],
    ushort amp_id [[amplification_id]],
    constant UniformsArray &uniformsArray [[buffer(BufferIndexUniforms)]])
{
    const Uniforms uniforms = uniformsArray.uniforms[amp_id];
    const float4 position = float4(in.position, 1.0);
    return {
        .position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position,
        .texCoord = in.texCoord,
    };
}

fragment float4 fragmentShader(
    ShaderIn in [[stage_in]],
    texture2d<half> colorMap [[texture(TextureIndexColor)]])
{
    constexpr sampler colorSampler(mip_filter::linear, mag_filter::linear, min_filter::linear);
    half4 colorSample = colorMap.sample(colorSampler, in.texCoord.xy);
    return float4(colorSample);
}
