#import <metal_stdlib>
#import <simd/simd.h>

using namespace metal;

struct Vertex {
    vector_float3 position [[attribute(0)]];
    vector_float3 normal [[attribute(1)]];
    vector_float2 textureCoords [[attribute(2)]];
};

struct DemoBlitVertexUniforms {
    simd_float3x4 transform;
};

struct Fragment {
    vector_float4 position [[position]];
    float2 textureCoords;
};

// MARK: -

enum DemoBlitID {
    kDemoBlitID_Vertices = 0,
    kDemoBlitID_VertexShaderUniforms = 1,
    kDemoBlitID_BaseColorTexture = 0,
    kDemoBlitID_BaseColorSampler = 0,
};

// MARK: -

[[vertex]]
Fragment demoBlitVertexShader(
    Vertex vertexIn [[stage_in]],
    constant DemoBlitVertexUniforms &uniforms [[buffer(kDemoBlitID_VertexShaderUniforms)]]
    )
{
    return {
        .position = vector_float4(vector_float4(vertexIn.position, 1.0) * uniforms.transform, 1.0),
        .textureCoords = vertexIn.textureCoords
    };
}

[[fragment]]
vector_float4 demoBlitFragmentShader(
    Fragment fragmentIn [[stage_in]],
    texture2d<float> texture [[texture(kDemoBlitID_BaseColorTexture)]],
    sampler sampler[[sampler(kDemoBlitID_BaseColorSampler)]]
)
{
    return texture.sample(sampler, fragmentIn.textureCoords);
}
