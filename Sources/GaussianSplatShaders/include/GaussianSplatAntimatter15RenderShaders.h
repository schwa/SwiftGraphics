#import <simd/simd.h>

#ifdef __METAL_VERSION__
#import <metal_stdlib>
#import <metal_logging>
#import <metal_uniform>

namespace GaussianSplatAntimatter15RenderShaders {

constant bool debug [[function_constant(1)]];

inline float3x3 truncateTo3x3(const float4x4 M) {
    return float3x3(M[0].xyz, M[1].xyz, M[2].xyz);
}

using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 relativePosition;
    float4 color;
};

typedef VertexOut FragmentIn;

// MARK: -

[[vertex]]
VertexOut vertexMain(
    VertexIn in [[stage_in]],
    uint instance_id[[instance_id]],
    uint vertex_id[[vertex_id]],
    constant SplatX *splats [[buffer(2)]],
    constant IndexedDistance *indexedDistances [[buffer(3)]],
    constant float4x4 &modelMatrix [[buffer(4)]],
    constant float4x4 &viewMatrix [[buffer(5)]],
    constant float4x4 &projectionMatrix [[buffer(6)]],
    constant float2 &drawableSize [[buffer(7)]],
    constant float &splatScale [[buffer(8)]]
) {
    VertexOut out;
    const uint splatIndex = indexedDistances[instance_id].index;
    const SplatX splat = splats[splatIndex];
    const float2 focal = float2(projectionMatrix[1][1], -projectionMatrix[2][2]) * drawableSize / 2.0;
    const float4x4 modelViewMatrix = viewMatrix * modelMatrix;
    const float4 cam = modelViewMatrix * float4(splat.position, 1);
    float4 pos2d = projectionMatrix * cam;

//    if (instance_id == 0) {
////        os_log_default.log("instance_id : %d", instance_id);
//        os_log_default.log("focal: (%v2hlf)", focal);
////        os_log_default.log("projectionMatrix[1][1], projectionMatrix[2][2]: (%f, %f)", projectionMatrix[1][1], projectionMatrix[2][2]);
////        os_log_default.log("pos2d: (%v4hlf)", pos2d);
////        os_log_default.log("projection: (%f, %f, %f, %f), (%f, %f, %f, %f), (%f, %f, %f, %f), (%f, %f, %f, %f)",
////            projectionMatrix[0][0], projectionMatrix[1][0], projectionMatrix[2][0], projectionMatrix[3][0], // Column 1
////            projectionMatrix[0][1], projectionMatrix[1][1], projectionMatrix[2][1], projectionMatrix[3][1], // Column 2
////            projectionMatrix[0][2], projectionMatrix[1][2], projectionMatrix[2][2], projectionMatrix[3][2], // Column 3
////            projectionMatrix[0][3], projectionMatrix[1][3], projectionMatrix[2][3], projectionMatrix[3][3]  // Column 4
////        );
//    }

    const float clip = 1.2 * pos2d.w;
    if (pos2d.z < -clip || pos2d.x < -clip || pos2d.x > clip || pos2d.y < -clip || pos2d.y > clip) {
        out.position = float4(0.0, 0.0, 2.0, 1.0);
        return out;
    }

    const float2 u1 = float2(splat.u1);
    const float2 u2 = float2(splat.u2);
    const float2 u3 = float2(splat.u3);
    const float3x3 Vrk = float3x3(
        u1.x, u1.y, u2.x,
        u1.y, u2.y, u3.x,
        u2.x, u3.x, u3.y
    );
    const float3x3 J = float3x3(
        focal.x / cam.z, 0, -(focal.x * cam.x) / (cam.z * cam.z),
        0, focal.y / cam.z, -(focal.y * cam.y) / (cam.z * cam.z),
        0, 0, 0
    );
    const float3x3 T = transpose(truncateTo3x3(modelViewMatrix)) * J;
    const float3x3 cov2d = transpose(T) * Vrk * T;

    const float mid = (cov2d[0][0] + cov2d[1][1]) / 2.0;
    const float radius = length(float2((cov2d[0][0] - cov2d[1][1]) / 2.0, cov2d[0][1]));
    const float lambda1 = mid + radius;
    const float lambda2 = mid - radius;

    if (lambda2 < 0.0) {
        out.position = float4(0.0, 0.0, 2.0, 1.0);
        return out;
    }

    float2 diagonalVector = normalize(float2(cov2d[0][1], lambda1 - cov2d[0][0]));
    if (any(isnan(diagonalVector))) {
        diagonalVector = float2(1.0, 0.0); // default value to avoid NaN
    }
    const float2 majorAxis = min(sqrt(2.0 * lambda1), 1024.0) * diagonalVector;
    const float2 minorAxis = min(sqrt(2.0 * lambda2), 1024.0) * float2(diagonalVector.y, -diagonalVector.x);

    out.color = clamp(pos2d.z / pos2d.w + 1.0, 0.0, 1.0) * float4(splat.color) / 255.0;

    const float2 vCenter = pos2d.xy / pos2d.w;
    const float3 vertexPosition = in.position * splatScale * 2.0;
    const float2 position = vertexPosition.x * majorAxis / drawableSize + vertexPosition.y * minorAxis / drawableSize;
    out.relativePosition = in.position.xy * 2;


    out.position = float4(vCenter + position, 0.0, 1.0);
    return out;
}

// MARK: -

[[fragment]]
float4 fragmentMain(
    FragmentIn in [[stage_in]],
    uint primitive_id[[primitive_id]]
) {

    if (debug) {
        switch (primitive_id) {
            case 0:
                return float4(1, 0, 0, 1);
            case 1:
                return float4(0, 1, 0, 1);
            default:
                return float4(0, 0, 0, 0);
        }

    }
    else {
        float A = -dot(in.relativePosition, in.relativePosition);
        if (A < -4.0) {
            discard_fragment();
        }
        float B = exp(A) * in.color.a;
        return float4(B * in.color.rgb, B);

    }
}

};
#endif // __METAL_VERSION__
