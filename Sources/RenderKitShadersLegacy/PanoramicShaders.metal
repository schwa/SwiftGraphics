#import "include/RenderKitShaders.h"

typedef SimpleVertex Vertex;

struct Fragment {
    float4 position [[position]]; // in projection space
    float2 textureCoordinate;
};

// MARK: -

[[vertex]]
Fragment panoramicVertexShader(
    Vertex in [[stage_in]],
    constant CameraUniforms &cameraUniforms [[buffer(1)]],
    constant float4x4 &modelViewMatrix [[buffer(2)]]
)
{
    const float4 modelVertex = modelViewMatrix * float4(in.position, 1.0);
//    const float4 modelVertex = float4(in.position, 1.0);
    return {
        .position = cameraUniforms.projectionMatrix * modelVertex,
        .textureCoordinate = in.textureCoordinate
    };
}

[[fragment]]
vector_float4 panoramicFragmentShader(
    Fragment in [[stage_in]],
    constant PanoramaFragmentUniforms &uniforms[[buffer(0)]],
    array<texture2d<float, access::sample>, 12> tiles [[texture(0)]]
    )
{
    float4 color;
    // Special-case single texture panoramas.
    if (tiles.size() == 1) {
        const auto texture = tiles[0];
        color = texture.sample(RenderKitShaders::basicSampler, in.textureCoordinate);
    }
    else {
        const float2 denormalizedTextureCoordinate = in.textureCoordinate * float2(uniforms.gridSize);
        const ushort textureIndex = clamp(ushort(denormalizedTextureCoordinate.y) * uniforms.gridSize.x + ushort(denormalizedTextureCoordinate.x), 0, ushort(tiles.size()) - 1);
        const float2 textureCoordinate = denormalizedTextureCoordinate - floor(denormalizedTextureCoordinate);
        const auto texture = tiles[textureIndex];
        //    const float d = 1.0 / float(texture.get_width());
        //    if (textureCoordinate.x <= d || textureCoordinate.x >= 1 - d || textureCoordinate.y < d || textureCoordinate.y > 1 - d) {
        //        return float4(1, 0, 0, 1);
        //    }
        color = texture.sample(RenderKitShaders::basicSampler, textureCoordinate);
    }
    color *= uniforms.colorFactor;
    return color;
}
