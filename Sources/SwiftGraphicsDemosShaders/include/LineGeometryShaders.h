#import <simd/simd.h>

struct LineGeometryShadersInstance {
    float2 start;
    float2 end;
    float width;
    float4 color;
};

#ifdef __METAL_VERSION__

#import <metal_stdlib>

using namespace metal;


namespace LineGeometryShaders {

    struct VertexIn {
        float2 position [[attribute(0)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float4 color;
    };

    typedef VertexOut FragmentIn;
    typedef LineGeometryShadersInstance Instance;

    // MARK: -

    [[vertex]]
    VertexOut vertexShader(
        VertexIn in [[stage_in]],
        constant float2 &drawableSize [[buffer(1)]],
        constant Instance *instances [[buffer(2)]],
        uint instance_id [[instance_id]]
    )
    {
        auto instance = instances[instance_id];

        float2 direction = instance.end - instance.start;
        float lineLength = length(direction);

        // Calculate the perpendicular vector
        float2 perpendicular = float2(-direction.y, direction.x);

        // Normalize the direction and perpendicular vectors
        direction = normalize(direction);
        perpendicular = normalize(perpendicular);

        // Calculate the position of the vertex
        float2 position = instance.start + direction * in.position.x * lineLength
                        + perpendicular * (in.position.y - 0.5) * instance.width;

        VertexOut out;
        out.position = float4(position / drawableSize - 1, 0, 1);
        out.position.y *= -1;
        out.color = instance.color;

        return out;
    }

    // MARK: -

    [[fragment]]
    float4 fragmentShader(
        FragmentIn in [[stage_in]]
    )
    {
        return in.color;
    }

};
#endif
