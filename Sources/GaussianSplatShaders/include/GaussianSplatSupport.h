#import <simd/simd.h>

struct IndexedDistance {
    unsigned int index;
    float distance;
};

struct GaussianSplatUniforms {
    simd_float4x4 modelViewProjectionMatrix;
    simd_float4x4 modelViewMatrix;
    simd_float2 drawableSize;
    float discardRate;
    simd_float2 focalSize; // drawableSize * helper.projectionMatrix.diagonal.xy / 2
    simd_float2 limit; // 1.3 * 1 / helper.projectionMatrix[0][0]/[1][1]
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
// TODO: could be replaced by half3x2
    packed_half3 cov_a;
    packed_half3 cov_b;
};
#endif


// MARK: -

#ifdef __METAL_VERSION__
#import <metal_stdlib>

using namespace metal;

namespace GaussianSplatShaders {

    float3 calcCovariance2D(float3 viewPos, packed_half3 cov3Da, packed_half3 cov3Db, float4x4 modelViewMatrix, float2 focalSize, float2 limit)
    {
        float invViewPosZ = 1 / viewPos.z;
        float invViewPosZSquared = invViewPosZ * invViewPosZ;

        viewPos.x = clamp(viewPos.x * invViewPosZ, -limit.x, limit.x) * viewPos.z;
        viewPos.y = clamp(viewPos.y * invViewPosZ, -limit.y, limit.y) * viewPos.z;

        float3x3 J = float3x3(
            focalSize.x * invViewPosZ, 0, 0,
            0, focalSize.y * invViewPosZ, 0,
            -(focalSize.x * viewPos.x) * invViewPosZSquared, -(focalSize.y * viewPos.y) * invViewPosZSquared, 0
        );
        float3x3 W = float3x3(modelViewMatrix[0].xyz, modelViewMatrix[1].xyz, modelViewMatrix[2].xyz);
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

    Tuple2<float2> decomposedCalcCovariance2D(float3 viewPos, packed_half3 cov3Da, packed_half3 cov3Db, float4x4 modelViewMatrix, float2 focalSize, float2 limit) {
        const float3 cov2D = calcCovariance2D(viewPos, cov3Da, cov3Db, modelViewMatrix, focalSize, limit);
        const Tuple2<float2> axes = decomposeCovariance(cov2D);
        return axes;
    }


}
#endif // __METAL_VERSION__
