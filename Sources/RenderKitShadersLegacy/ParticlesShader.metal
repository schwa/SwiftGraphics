#import "include/RenderKitShaders.h"

typedef SimpleVertex Vertex;

struct Fragment {
    float4 position [[position]]; // in projection space
    float2 textureCoordinate;
};

// MARK: -

[[vertex]]
Fragment particleVertexShader(
    Vertex in [[stage_in]],
    ushort instance_id[[instance_id]],
    constant CameraUniforms &cameraUniforms [[buffer(1)]],
    constant float2 *positions [[buffer(2)]]
)
{
    const float particleSize = 10.0;

    auto position = positions[instance_id];
    const float4 modelVertex = float4(in.position * particleSize * 2 + float3(position, 0), 1);
    return {
        .position = cameraUniforms.projectionMatrix * modelVertex,
        .textureCoordinate = in.textureCoordinate
    };
}

[[fragment]]
vector_float4 particleFragmentShader(
    Fragment in [[stage_in]]
    )
{
    const float d = 0.25 - distance_squared(in.textureCoordinate, float2(0.5, 0.5));
    return float4(1, 0, 0, d > 0 ? 1.0 : 0.0);
}
