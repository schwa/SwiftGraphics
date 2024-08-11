struct UnlitMaterial {
    float4 color;
    short textureIndex; // or -1 for no texture
};

#ifdef __METAL_VERSION__

typedef SimpleVertex Vertex;



struct Fragment {
    float4 position [[position]]; // in projection space
    float2 textureCoordinate;
    ushort instance_id [[flat]]; // TODO: is flat needed?
};

// MARK: -

[[vertex]]
Fragment unlitVertexShader(
    Vertex in [[stage_in]],
    ushort instance_id[[instance_id]],
    constant CameraUniformsNEW &camera[[buffer(1)]],
    constant ModelTransformsNEW *models[[buffer(2)]] // TODO: rename to modelTransforms
)
{
    const ModelTransformsNEW model = models[instance_id];
    const float4 modelVertex = model.modelViewMatrix * float4(in.position, 1.0);
    return {
        .position = camera.projectionMatrix * modelVertex,
        .textureCoordinate = in.textureCoordinate,
        .instance_id = instance_id,
    };
}

[[fragment]]
vector_float4 unlitFragmentShader(
    Fragment in [[stage_in]],
    constant UnlitMaterial *materials [[buffer(0)]],
    array<texture2d<float, access::sample>, 1> textures [[texture(0)]]
    )
{
    float4 color;
    auto material = materials[in.instance_id];
    if (material.textureIndex == -1) {
        color = materials[in.instance_id].color;
    }
    else {
        auto texture = textures[material.textureIndex];
        color = texture.sample(RenderKitShaders::basicSampler, in.textureCoordinate);
    }
    return color;
}
#endif
