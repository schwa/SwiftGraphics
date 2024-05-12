#import "include/RenderKitShaders.h"
#import "include/GraphToy.h"

using namespace metal;
using namespace graphtoy;

struct Fragment {
    float4 position [[position]]; // in projection space
    float3 modelPosition;
    float2 textureCoordinate;
};

// MARK: -

[[vertex]]
Fragment gridVertexShader(
    SimpleVertex in [[stage_in]],
    ushort instance_id[[instance_id]],
    constant CameraUniforms &cameraUniforms [[buffer(1)]],
    constant ModelTransforms *instancedModelUniforms [[buffer(2)]]
    )
{
    const ModelTransforms modelUniforms = instancedModelUniforms[instance_id];
    const float4 modelVertex = modelUniforms.modelViewMatrix * float4(in.position, 1.0);
    return {
        .position = cameraUniforms.projectionMatrix * modelVertex,
        .modelPosition = float3(modelVertex) / modelVertex.w,
        .textureCoordinate = in.textureCoordinate,
    };
}

#define ddx dfdx
#define ddy dfdy
#define frac fract

// https://bgolus.medium.com/the-best-darn-grid-shader-yet-727f9278b9d8
[[fragment]]
float4 gridFragmentShader(
    Fragment in [[stage_in]])
{
    auto uv = in.textureCoordinate;
    const float2 lineWidth = {1.0, 1.0 };
    float4 uvDDXY = float4(ddx(uv), ddy(uv)); //
    float2 uvDeriv = float2(length(uvDDXY.xz), length(uvDDXY.yw)); //
    bool2 invertLine = lineWidth > 0.5;
    float2 targetWidth = (invertLine.x || invertLine.y) ? 1.0 - lineWidth : lineWidth;
    float2 drawWidth = clamp(targetWidth, uvDeriv, 0.5);
    float2 lineAA = uvDeriv * 1.5;
    float2 gridUV = abs(frac(uv) * 2.0 - 1.0);
    gridUV = (invertLine.x || invertLine.y) ? gridUV : 1.0 - gridUV;
    float2 grid2 = smoothstep(drawWidth + lineAA, drawWidth - lineAA, gridUV);
    grid2 *= saturate(targetWidth / drawWidth);
    grid2 = lerp(grid2, targetWidth, saturate(uvDeriv * 2.0 - 1.0));
    grid2 = (invertLine.x || invertLine.y) ? 1.0 - grid2 : grid2;
    float grid = lerp(grid2.x, 1.0, grid2.y);


    return { grid, grid, grid, 1.0 };
}
