#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct ShaderToyVertex {
    vector_float3 position [[attribute(0)]];
    vector_float3 normal [[attribute(1)]];
    vector_float2 textureCoords [[attribute(2)]];
};

struct ShaderToyVertexUniforms {
    simd_float3x4 transform;
};

struct ShaderToyFragmentUniforms {
    float time;
    vector_float2 scale;
};

struct Fragment {
    vector_float4 position [[position]];
};

// MARK: -

enum ShaderToyID {
    kShaderToyID_Vertices = 0,
    kShaderToyID_VertexShaderUniforms = 1,
    kShaderToyID_FragmentShaderUniforms = 2,
    kShaderToyID_PixelateFunctionConstant = 0,
};

// MARK: -

constant bool pixelate [[function_constant(kShaderToyID_PixelateFunctionConstant)]];

[[vertex]]
Fragment shaderToyVertexShader(ShaderToyVertex vertexIn [[stage_in]], constant ShaderToyVertexUniforms &uniforms [[buffer(kShaderToyID_VertexShaderUniforms)]])
{
    return {
        .position = vector_float4(vector_float4(vertexIn.position, 1.0) * uniforms.transform, 1.0)
    };
}

[[fragment]]
vector_float4 shaderToyFragmentShader(Fragment fragmentIn [[stage_in]], constant ShaderToyFragmentUniforms &uniforms [[buffer(kShaderToyID_FragmentShaderUniforms)]])
{
    vector_float2 vert = fragmentIn.position.xy * uniforms.scale;
    if (pixelate) {
        vert = floor(vert);
    }
    const auto step = vector_float2(sin(uniforms.time), cos(uniforms.time)) * 20.0;
    const auto scale = ((sin(uniforms.time / 60.0) + 1.0) / 5.0) + 0.2;
    const auto r = sin((vert.x + step.x) * scale) + cos((vert.y + step.x) * scale);
    const auto g = sin((vert.x + step.x) * scale) + cos((vert.y + step.y) * scale);
    const auto b = sin((vert.x + step.y) * scale) + cos((vert.y + step.y) * scale);
    return vector_float4(r, g, b, 1.0);
}
