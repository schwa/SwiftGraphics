#import <simd/simd.h>

struct IndexedDistance {
    unsigned int index;
    float distance;
};

struct GaussianSplatUniforms {
    simd_float4x4 modelViewProjectionMatrix;
    simd_float4x4 modelViewMatrix;
    simd_float4x4 projectionMatrix;
    simd_float4x4 viewMatrix;
    simd_float3 cameraPosition;
    simd_float2 drawableSize;
    float discardRate;
};

#ifdef __METAL_VERSION__
// Antimatter style
struct SplatB {
    packed_float3 position; //  0 ..< 12
    packed_float3 scale;    // 12 ..< 24
    uchar4 color;           // 24 ..< 28
    uchar4 rotation;        // 28 ..< 32
};

// Sean style
struct SplatC {
    packed_half3 position;
    packed_half4 color;
    packed_half3 cov_a;
    packed_half3 cov_b;
};
#endif


// MARK: -

#ifdef __METAL_VERSION__
#import <metal_stdlib>

using namespace metal;

namespace GaussianSplatShaders {

    float3 calcCovariance2D(float3 viewPos, packed_half3 cov3Da, packed_half3 cov3Db, float4x4 viewMatrix, float4x4 projectionMatrix, float2 screenSize)
    {
        float invViewPosZ = 1 / viewPos.z;
        float invViewPosZSquared = invViewPosZ * invViewPosZ;

        float tanHalfFovX = 1 / projectionMatrix[0][0];
        float tanHalfFovY = 1 / projectionMatrix[1][1];
        float limX = 1.3 * tanHalfFovX;
        float limY = 1.3 * tanHalfFovY;
        viewPos.x = clamp(viewPos.x * invViewPosZ, -limX, limX) * viewPos.z;
        viewPos.y = clamp(viewPos.y * invViewPosZ, -limY, limY) * viewPos.z;

        float focalX = screenSize.x * projectionMatrix[0][0] / 2;
        float focalY = screenSize.y * projectionMatrix[1][1] / 2;

        float3x3 J = float3x3(
            focalX * invViewPosZ, 0, 0,
            0, focalY * invViewPosZ, 0,
            -(focalX * viewPos.x) * invViewPosZSquared, -(focalY * viewPos.y) * invViewPosZSquared, 0
        );
        float3x3 W = float3x3(viewMatrix[0].xyz, viewMatrix[1].xyz, viewMatrix[2].xyz);
        float3x3 T = J * W;
        float3x3 Vrk = float3x3(
            cov3Da.x, cov3Da.y, cov3Da.z,
            cov3Da.y, cov3Db.x, cov3Db.y,
            cov3Da.z, cov3Db.y, cov3Db.z
        );
        float3x3 cov = T * Vrk * transpose(T);

        // Apply low-pass filter: every Gaussian should be at least one pixel wide/high. Discard 3rd row and column.
        cov[0][0] += 0.3;
        cov[1][1] += 0.3;
        return float3(cov[0][0], cov[0][1], cov[1][1]);
    }

    template <typename T>
    struct Tuple2 {
        T v0;
        T v1;
    };

    // cov2D is a flattened 2d covariance matrix. Given
    // covariance = | a b |
    //              | c d |
    // (where b == c because the Gaussian covariance matrix is symmetric),
    // cov2D = ( a, b, d )
    Tuple2<float2> decomposeCovariance(float3 cov2D) {
        float a = cov2D.x;
        float b = cov2D.y;
        float d = cov2D.z;
        // matrix is symmetric, so "c" is same as "b"
        float det = a * d - b * b;
        float trace = a + d;
        float mean = 0.5 * trace;
        // based on https://github.com/graphdeco-inria/diff-gaussian-rasterization/blob/main/cuda_rasterizer/forward.cu
        float dist = max(0.1, sqrt(mean * mean - det));
        // Eigenvalues
        float lambda1 = mean + dist;
        float lambda2 = mean - dist;
        float2 eigenvector1;
        if (b == 0) {
            eigenvector1 = (a > d) ? float2(1, 0) : float2(0, 1);
        } else {
            eigenvector1 = normalize(float2(b, d - lambda2));
        }
        // Gaussian axes are orthogonal
        float2 eigenvector2 = float2(eigenvector1.y, -eigenvector1.x);
        auto v1 = eigenvector1 * sqrt(lambda1 * 2);
        auto v2 = eigenvector2 * sqrt(lambda2 * 2);
        return { v1, v2 };
    }

}
#endif // __METAL_VERSION__
