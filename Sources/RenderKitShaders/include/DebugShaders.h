struct DebugVertexShaderUniforms
{
    float4x4 modelViewProjectionMatrix;
    float3 positionOffset;
};

struct DebugFragmentShaderUniforms
{
    float2 windowSize;
};

#ifdef __METAL_VERSION__
using namespace metal;
typedef SimpleVertex DebugVertexIn;

struct DebugVertexOut {
    float4 position [[position]];
    float3 normal;
};

typedef DebugVertexOut DebugFragmentIn;

struct DebugFragmentOut {
    float4 fragColor [[color(0)]];
};
// MARK: -

vertex DebugVertexOut DebugVertexShader(
    DebugVertexIn in [[stage_in]],
    constant DebugVertexShaderUniforms& uniforms [[buffer(1)]]
    )
{
    return {
        .position = uniforms.modelViewProjectionMatrix * float4(in.position, 1) + float4(uniforms.positionOffset, 0),
        .normal = in.normal,
    };
}

fragment DebugFragmentOut DebugFragmentShader(DebugFragmentIn in [[stage_in]],
    constant DebugFragmentShaderUniforms& uniforms [[buffer(0)]],
    bool is_front_face [[front_facing]],
    uint primitive_id [[primitive_id]]
    )
{
    float4 baseColor = { 1, 0, 0, 1 };


    if (false) {
        auto n = random(float2(float(primitive_id), 0));
        baseColor = kellyColor(n);
    }

    if (false) {
        const float error = 0.1;
        if (abs(length(in.normal - float3(1, 0, 0))) < error) {
            baseColor = { 1, 0, 0, 1 };
        }
        else if (abs(length(in.normal - float3(0, 1, 0))) < error) {
            baseColor = { 0, 1, 0, 1 };
        }
        else if (abs(length(in.normal - float3(0, 0, 1))) < error) {
            baseColor = { 0, 0, 1, 1 };
        }
        else if (abs(length(in.normal - float3(-1, 0, 0))) < error) {
            baseColor = { 1, 1, 0, 1 };
        }
        else if (abs(length(in.normal - float3(0, -1, 0))) < error) {
            baseColor = { 0, 1, 1, 1 };
        }
        else if (abs(length(in.normal - float3(0, 0, -1))) < error) {
            baseColor = { 1, 0, 1, 1 };
        }
        else {
            baseColor = { 0.2, 0.2, 0.2, 1 };
        }
    }

//    if (!is_front_face) {
//        baseColor *= 0.1;
//    }

    return {
        .fragColor = baseColor
    };
}
#endif
