#import "include/RenderKitShaders.h"

typedef SimpleVertex Vertex;

struct Fragment {
    float4 position [[position]]; // in projection space
};

// MARK: -

[[vertex]]
Fragment reallyFlatVertexShader(
    Vertex in [[stage_in]],
    ushort instance_id[[instance_id]],
    constant CameraUniforms &cameraUniforms [[buffer(1)]],
    constant float2 &position [[buffer(2)]]
)
{
    const float4 modelVertex = float4(in.position + float3(position, 0), 1);
    return {
        .position = cameraUniforms.projectionMatrix * modelVertex,
    };
}

[[fragment]]
vector_float4 reallyFlatFragmentShader(
    Fragment in [[stage_in]]
    )
{
    return float4(1, 0, 0, 1);
}
