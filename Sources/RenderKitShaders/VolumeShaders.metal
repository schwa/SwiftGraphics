#import "include/RenderKitShaders.h"
#import "include/VolumeShaders.h"

typedef SimpleVertex Vertex;

struct VertexOut {
    float4 position [[position]]; // in projection space
    float3 textureCoordinate;
};
typedef VertexOut FragmentIn;

// MARK: -

[[vertex]]
VertexOut volumeVertexShader(
    Vertex in [[stage_in]],
    constant CameraUniforms &cameraUniforms [[buffer(1)]],
    constant VolumeTransforms &transforms [[buffer(2)]],
    constant VolumeInstance *instances [[buffer(3)]],
    ushort instance_id [[instance_id]]
    )
{
    const VolumeInstance instance = instances[instance_id];
    const float4 offset = float4(0, 0, instance.offsetZ, 1.0);
    const float3 textureCoordinate = float3(in.textureCoordinate, instance.textureZ);

    // Kill rotation from modelView matrix.
    // TODO: This also kills scale.
    float4x4 modelViewMatrix = transforms.modelViewMatrix;
    // TODO: Hack the scale in here until i can bothered to fix this.
    modelViewMatrix[0][0] = 2.0;
    modelViewMatrix[0][1] = 0.0;
    modelViewMatrix[0][2] = 0.0;
    modelViewMatrix[1][0] = 0.0;
    modelViewMatrix[1][1] = 2.0;
    modelViewMatrix[1][2] = 0.0;
    modelViewMatrix[2][0] = 0.0;
    modelViewMatrix[2][1] = 0.0;
    modelViewMatrix[2][2] = 2.0;

    float4x4 textureMatrix = transforms.textureMatrix;
    float3 rotatedTextureCoordinate = (textureMatrix * float4(textureCoordinate.xyz, 1.0)).xzy;
    const float4 modelVertex = modelViewMatrix * float4(in.position + offset.xyz, 1.0);
    const float4 clipSpace = cameraUniforms.projectionMatrix * modelVertex;
    return {
        .position = clipSpace,
        .textureCoordinate = rotatedTextureCoordinate,
    };
}

// MARK: -

[[fragment]]
float4 volumeFragmentShader(
    FragmentIn in [[stage_in]],
    texture3d<unsigned short, access::sample> texture [[texture(0)]],
    texture1d<float, access::sample> transferFunctionTexture [[texture(1)]],
    constant VolumeFragmentUniforms &uniforms [[buffer(0)]]
    )
{
    if (
        in.textureCoordinate.x < 0 || in.textureCoordinate.x > 1.0
        || in.textureCoordinate.y < 0 || in.textureCoordinate.y > 1.0
        || in.textureCoordinate.z < 0 || in.textureCoordinate.z > 1.0
        ) {
        discard_fragment();
    }
    constexpr struct sampler basicSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    const float normalizedValue = texture.sample(basicSampler, in.textureCoordinate).r / float(uniforms.maxValue);
    auto color = transferFunctionTexture.sample(basicSampler, normalizedValue);

    // Alpha adjusted by number of instances so we don't blow out the brightness.
    return color * float4(1, 1, 1, 1 / float(uniforms.instanceCount) * uniforms.alpha);
}
