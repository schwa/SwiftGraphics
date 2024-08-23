struct UnlitShaderInstance {
    float4 color;
    short textureIndex; // or -1 for no texture
};

#ifdef __METAL_VERSION__

typedef SimpleVertex Vertex;

struct Fragment {
    float4 position [[position]]; // in projection space
    float2 textureCoordinate;
    float3 modelSpacePosition;
    ushort instance_id [[flat]]; // TODO: is flat needed?
};

// MARK: -

namespace UnlitShader {

    constant bool derive_texture_coordinates [[function_constant(1)]];

    vec2 uv_of_camera(vec3 modelSpacePosition, vec3 location, float rotation) {
        const float3 d = modelSpacePosition - location;
        const float r = length(d.xz);
        const float u = fract((atan2(d.x, -d.z) / M_PI_F + 1.0) * 0.5 - rotation / (M_PI_F * 2.0));
        const float v = atan2(d.y, r) / M_PI_F + 0.5;
        return { u, v };
    }

    // MARK: -

    [[vertex]]
    Fragment unlitVertexShader(
       Vertex in [[stage_in]],
       ushort instance_id[[instance_id]],
       constant CameraUniformsNEW &camera[[buffer(1)]],
       constant ModelTransformsNEW *models[[buffer(2)]]
       )
    {
        const ModelTransformsNEW model = models[instance_id];
        const float4 modelVertex = model.modelViewMatrix * float4(in.position, 1.0);
        Fragment out = {
            .position = camera.projectionMatrix * modelVertex,
            .textureCoordinate = in.textureCoordinate,
            .modelSpacePosition = in.position,
            .instance_id = instance_id,
        };
        return out;
    }

    [[fragment]]
    vector_float4 unlitFragmentShader(
        Fragment in [[stage_in]],
        constant UnlitShaderInstance *instanceData [[buffer(0)]],
        constant float2 &textureRotation[[buffer(1)]],
        constant float3 &cameraPosition[[buffer(2)]],
        array<texture2d<float, access::sample>, 1> textures [[texture(0)]]

        )
    {
        float4 color;
        auto material = instanceData[in.instance_id];
        if (material.textureIndex == -1) {
            color = instanceData[in.instance_id].color;
        }
        else {
            float2 textureCoordinate;
            if (derive_texture_coordinates) {
                textureCoordinate = uv_of_camera(in.modelSpacePosition.xyz, cameraPosition, textureRotation.x);
            }
            else {
                textureCoordinate = in.textureCoordinate;
            }
            auto texture = textures[material.textureIndex];
            color = texture.sample(RenderKitShaders::basicSampler, textureCoordinate);
        }
        return color;
    }
}
#endif
