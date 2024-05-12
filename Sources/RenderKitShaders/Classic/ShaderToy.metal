#include <metal_stdlib>
#include <simd/simd.h>
#include "include/Shaders.h"

using namespace metal;

struct Fragment
{
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex Fragment ShaderToy_VertexShader(
    Vertex in [[stage_in]],
    constant Transforms &transforms [[buffer(CommonBindings_TransformsBuffer)]])
{
    Fragment out;
    out.position = transforms.projection * transforms.modelView * float4(in.position, 1.0);
    out.position.z -= 0.001; // TODO: Parameterize
    out.textureCoordinate = in.textureCoordinate;
    return out;
}

float plot(float2 st) {
    return smoothstep(0.02, 0.0, abs(st.y - st.x));
}

fragment float4 ShaderToy_FragmentShader(
    Fragment in [[stage_in]],
    constant FrameState &frameState [[buffer(CommonBindings_FrameStateBuffer)]])
{
    float2 st = in.textureCoordinate;
    float y = st.x;
    float3 color = float3(y);
    float pct = plot(st);
    color = (1.0-pct)*color+pct*float3(0.0,1.0,0.0);
    return float4(color,1.0);

    //return float4(sin(frameState.time * 4) / 2 + 0.5, 0, 0, 1);
    //return float4(in.textureCoordinate.x, 0, 0, 1);
}
