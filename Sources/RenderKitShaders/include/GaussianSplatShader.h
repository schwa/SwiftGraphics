#include <simd/simd.h>

struct GaussianSplatUniforms {
    simd_float4x4 modelViewProjectionMatrix;
    simd_float4x4 modelViewMatrix;
    simd_float4x4 projectionMatrix;
    simd_float4x4 modelMatrix;
    simd_float4x4 viewMatrix;
    simd_float3 cameraPosition;
    simd_float2 drawableSize;
};

struct GaussianSplatSortUniforms {
    unsigned int splatCount;
    unsigned int groupWidth;
    unsigned int groupHeight;
    unsigned int stepIndex;
};

#ifdef __METAL_VERSION__
#include <metal_stdlib>

namespace GaussianSplatShader {

    using namespace metal;

    struct VertexIn {
        float3 position  [[attribute(0)]];
//        float3 normal    [[attribute(1)]];
//        float2 texCoords [[attribute(2)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float2 relativePosition; // Ranges from -kBoundsRadius to +kBoundsRadius
        float4 color;
    };

    struct SplatC {
        packed_half3 position;
        packed_half4 color;
        packed_half3 cov_a;
        packed_half3 cov_b;
    };

    typedef SplatC Splat;

    typedef GaussianSplatUniforms VertexUniforms;
    typedef GaussianSplatUniforms FragmentUniforms;
    typedef VertexOut FragmentIn;

    struct FragmentOut {
        float4 fragColor [[color(0)]];
    };

    // MARK: -

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

    // cov2D is a flattened 2d covariance matrix. Given
    // covariance = | a b |
    //              | c d |
    // (where b == c because the Gaussian covariance matrix is symmetric),
    // cov2D = ( a, b, d )
    void decomposeCovariance(float3 cov2D, thread float2 &v1, thread float2 &v2) {
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
        lambda1 *= 2;
        lambda2 *= 2;
        v1 = eigenvector1 * sqrt(lambda1);
        v2 = eigenvector2 * sqrt(lambda2);
    }

    void decomposeCalculatedCovariance(float3 viewPos, packed_half3 cov3Da, packed_half3 cov3Db, float4x4 viewMatrix, float4x4 projectionMatrix, float2 screenSize, thread float2 &v1, thread float2 &v2) {
        float3 cov2D = calcCovariance2D(viewPos, cov3Da, cov3Db, viewMatrix, projectionMatrix, screenSize);
        float2 axis1;
        float2 axis2;
        decomposeCovariance(cov2D, axis1, axis2);
        v1 = axis1;
        v2 = axis2;
    }


    // MARK: -

    constant static const float kBoundsRadius = 2;
    constant static const float kBoundsRadiusSquared = kBoundsRadius * kBoundsRadius;

    [[vertex]]
    VertexOut VertexShader(
        VertexIn in [[stage_in]],
        uint instance_id[[instance_id]],
        uint vertex_id[[vertex_id]],
        constant VertexUniforms &uniforms [[buffer(1)]],
        constant Splat *splats [[buffer(2)]],
        constant uint *splatIndices [[buffer(3)]]
   ) {
        VertexOut out;

        auto splat = splats[splatIndices[instance_id]];
        const auto splatWorldSpacePosition = uniforms.modelViewMatrix * float4(float3(splat.position), 1);
        const auto splatClipSpacePosition = uniforms.projectionMatrix * splatWorldSpacePosition;

        const auto bounds = 1.2 * splatClipSpacePosition.w;
        if (splatClipSpacePosition.z < -splatClipSpacePosition.w
            || splatClipSpacePosition.x < -bounds
            || splatClipSpacePosition.x > bounds
            || splatClipSpacePosition.y < -bounds
            || splatClipSpacePosition.y > bounds) {
            out.position = float4(1, 1, 0, 1);
            return out;
        }

//        const float2 relativeCoordinatesArray[] = { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } };
//        const auto vertexModelSpacePosition2 = relativeCoordinatesArray[vertex_id];
        const auto vertexModelSpacePosition = in.position.xy;

        float2 axis1;
        float2 axis2;
        decomposeCalculatedCovariance(splatWorldSpacePosition.xyz, splat.cov_a, splat.cov_b, uniforms.modelViewMatrix, uniforms.projectionMatrix, uniforms.drawableSize, axis1, axis2);

        const auto projectedScreenDelta = (vertexModelSpacePosition.x * axis1 + vertexModelSpacePosition.y * axis2) * 2 * kBoundsRadius / uniforms.drawableSize;

        auto position = splatClipSpacePosition;
        position.xy += projectedScreenDelta.xy * splatClipSpacePosition.w;

        out.position = position;
        out.relativePosition = vertexModelSpacePosition * kBoundsRadius;
        out.color = float4(splat.color);
        return out;
    }

    // MARK: -

    [[fragment]]
    float4 FragmentShader(
        FragmentIn in [[stage_in]],
        constant FragmentUniforms &uniforms [[buffer(0)]],
        constant Splat *splats [[buffer(1)]],
        constant uint *splatIndices [[buffer(3)]]
    ) {
        const auto relativePosition = in.relativePosition;
        const auto negativeDistanceSquared = -dot(relativePosition, relativePosition);
        if (negativeDistanceSquared < -kBoundsRadiusSquared) {
            discard_fragment();
        }
        const auto falloff = exp(negativeDistanceSquared);
        const auto alpha = in.color.a * falloff;
        return float4(in.color.rgb * alpha, alpha);
    }

    // MARK: -

    [[kernel]]
    void DistancePreCalc(
        uint3 thread_position_in_grid [[thread_position_in_grid]],
        constant simd_float3x3 &modelMatrix[[buffer(0)]],
        constant simd_float3 &cameraPosition[[buffer(1)]],
        constant Splat *splats [[buffer(2)]],
        constant uint &splatCount [[buffer(3)]],
        device float *splatDistances [[buffer(4)]]
    ) {
        const uint index = thread_position_in_grid.x;
        if (index >= splatCount) {
            return;
        }
        const auto position = modelMatrix * float3(splats[index].position);
        const auto distance = distance_squared(position, cameraPosition);
        splatDistances[index] = distance;
    }

    // MARK: -

    [[kernel]]
    void BitonicSortSplats(
        uint3 thread_position_in_grid [[thread_position_in_grid]],
        constant GaussianSplatSortUniforms &uniforms [[buffer(0)]],
        constant float *splatDistances [[buffer(1)]],
        device uint *splatIndices [[buffer(2)]]
    ) {
        const auto index = thread_position_in_grid.x;
        const auto hIndex = index & (uniforms.groupWidth - 1);
        const auto indexLeft = hIndex + (uniforms.groupHeight + 1) * (index / uniforms.groupWidth);
        const auto stepSize = uniforms.stepIndex == 0 ? uniforms.groupHeight - 2 * hIndex : (uniforms.groupHeight + 1) / 2;
        const auto indexRight = indexLeft + stepSize;
        // Exit if out of bounds (for non-power of 2 input sizes)
        if (indexRight >= uniforms.splatCount) {
            return;
        }

        const auto valueLeft = splatIndices[indexLeft];
        const auto valueRight = splatIndices[indexRight];
        auto distanceLeft = splatDistances[valueLeft];
        auto distanceRight = splatDistances[valueRight];
        // Swap entries if value is descending
        if (distanceLeft < distanceRight) {
            // TODO: Does metal have a swap function?
            splatIndices[indexLeft] = valueRight;
            splatIndices[indexRight] = valueLeft;
        }
    }
}
#endif
