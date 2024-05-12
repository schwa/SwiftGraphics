#include <metal_stdlib>
#include "include/Common.h"
#include "include/Voxels.h"
//#include "include/Random.h"
#include "include/BlinnPhongShaders.h"
#include "include/Support.h"
#include "include/Shaders.h"


using namespace metal;

kernel void magicaVoxelsToColorTexture3D(uint gid [[thread_position_in_grid]],
                                         constant MagicaVoxel *voxels [[buffer(VoxelsBindings_VoxelsBuffer)]],
                                         texture1d<float, access::read> colorPalette [[texture(VoxelsBindings_ColorPaletteTexture)]],
                                         texture3d<float, access::write> outputTexture [[texture(VoxelsBindings_OutputTexture)]]
                                         )
{
    const auto voxel = voxels[gid];
    const auto color = colorPalette.read(ushort(voxel.color));
    outputTexture.write(color, ushort3(voxel.position));
}

kernel void magicaVoxelsToColorIndexTexture3D(uint gid [[thread_position_in_grid]],
                                              constant MagicaVoxel *voxels [[buffer(VoxelsBindings_VoxelsBuffer)]],
                                              texture3d<ushort, access::write> outputTexture [[texture(VoxelsBindings_OutputTexture)]]
                                              )
{
    const auto voxel = voxels[gid];
    outputTexture.write(voxel.color, ushort3(voxel.position));
}

// MARK: -

void copyCubeVertices(device PackedVoxelVertex *outVertices, device int *outIndices, half3 scale, half3 vertexOffset, int indexOffset, ushort colorIndex) {
    const PackedVoxelVertex vertices[] = {
        { { 0.000000, 1.000000, 1.000000 }, { 0.000000, 0.000000, 1.000000 }, { 0.875000, 0.500000 } },
        { { 1.000000, 0.000000, 1.000000 }, { 0.000000, 0.000000, 1.000000 }, { 0.625000, 0.750000 } },
        { { 1.000000, 1.000000, 1.000000 }, { 0.000000, 0.000000, 1.000000 }, { 0.625000, 0.500000 } },
        { { 1.000000, 0.000000, 1.000000 }, { 0.000000, -1.000000, 0.000000 }, { 0.625000, 0.750000 } },
        { { 0.000000, 0.000000, 0.000000 }, { 0.000000, -1.000000, 0.000000 }, { 0.375000, 1.000000 } },
        { { 1.000000, 0.000000, 0.000000 }, { 0.000000, -1.000000, 0.000000 }, { 0.375000, 0.750000 } },
        { { 0.000000, 0.000000, 1.000000 }, { -1.000000, 0.000000, 0.000000 }, { 0.625000, 0.000000 } },
        { { 0.000000, 1.000000, 0.000000 }, { -1.000000, 0.000000, 0.000000 }, { 0.375000, 0.250000 } },
        { { 0.000000, 0.000000, 0.000000 }, { -1.000000, 0.000000, 0.000000 }, { 0.375000, 0.000000 } },
        { { 1.000000, 1.000000, 0.000000 }, { 0.000000, 0.000000, -1.000000 }, { 0.375000, 0.500000 } },
        { { 0.000000, 0.000000, 0.000000 }, { 0.000000, 0.000000, -1.000000 }, { 0.125000, 0.750000 } },
        { { 0.000000, 1.000000, 0.000000 }, { 0.000000, 0.000000, -1.000000 }, { 0.125000, 0.500000 } },
        { { 1.000000, 1.000000, 1.000000 }, { 1.000000, 0.000000, -0.000000 }, { 0.625000, 0.500000 } },
        { { 1.000000, 0.000000, 0.000000 }, { 1.000000, 0.000000, -0.000000 }, { 0.375000, 0.750000 } },
        { { 1.000000, 1.000000, 0.000000 }, { 1.000000, 0.000000, -0.000000 }, { 0.375000, 0.500000 } },
        { { 0.000000, 1.000000, 1.000000 }, { 0.000000, 1.000000, -0.000000 }, { 0.625000, 0.250000 } },
        { { 1.000000, 1.000000, 0.000000 }, { 0.000000, 1.000000, -0.000000 }, { 0.375000, 0.500000 } },
        { { 0.000000, 1.000000, 0.000000 }, { 0.000000, 1.000000, -0.000000 }, { 0.375000, 0.250000 } },
        { { 0.000000, 0.000000, 1.000000 }, { 0.000000, -0.000000, 1.000000 }, { 0.875000, 0.750000 } },
        { { 0.000000, 0.000000, 1.000000 }, { 0.000000, -1.000000, 0.000000 }, { 0.625000, 1.000000 } },
        { { 0.000000, 1.000000, 1.000000 }, { -1.000000, 0.000000, 0.000000 }, { 0.625000, 0.250000 } },
        { { 1.000000, 0.000000, 0.000000 }, { 0.000000, 0.000000, -1.000000 }, { 0.375000, 0.750000 } },
        { { 1.000000, 0.000000, 1.000000 }, { 1.000000, 0.000000, 0.000000 }, { 0.625000, 0.750000 } },
        { { 1.000000, 1.000000, 1.000000 }, { 0.000000, 1.000000, -0.000000 }, { 0.625000, 0.500000 } },
    };

    for (int n = 0; n != 24; ++n) {
        outVertices[n] = vertices[n];
        outVertices[n].position = (outVertices[n].position + vertexOffset) * scale;
        outVertices[n].colorIndex = colorIndex;
    }

    const int baseIndices[] = {
        0, 1, 2,
        3, 4, 5,
        6, 7, 8,
        9, 10, 11,
        12, 13, 14,
        15, 16, 17,
        0, 18, 1,
        3, 19, 4,
        6, 20, 7,
        9, 21, 10,
        12, 22, 13,
        15, 23, 16,
    };

    for (int n = 0; n != 36; ++n) {
        outIndices[n] = colorIndex == 0 ? -1 : baseIndices[n] + indexOffset;
    }

}

// MARK: -

kernel void voxelsToVertices(uint gid [[thread_position_in_grid]],
                                 constant float3 &voxelSize[[buffer(VoxelsBindings_VoxelSizeBuffer )]],
                                 constant MagicaVoxel *voxels [[buffer(VoxelsBindings_VoxelsBuffer)]],
                                 device PackedVoxelVertex *vertices[[buffer(VoxelsBindings_VerticesBuffer)]],
                                 device int *indices[[buffer(VoxelsBindings_IndicesBuffer)]]
                                 )
{
    const auto voxel = voxels[gid];
    device PackedVoxelVertex *cubeVertices = vertices + (gid * 24);
    device int *cubeIndices = indices + (gid * 36);
    copyCubeVertices(cubeVertices, cubeIndices, half3(voxelSize), half3(voxel.position), gid * 24, voxel.color);
}

// MARK: -

struct Fragment
{
    float4 position [[position]];
    float3 modelPosition;
    float3 interpolatedNormal;
    float2 textureCoordinate;
    float4 color;
};

vertex Fragment VoxelVertexShader(
                                  VoxelVertex in [[stage_in]],
                                  constant Transforms &transforms [[buffer(CommonBindings_TransformsBuffer)]],
                                  texture1d<float, access::read> colorPalette [[texture(VoxelsBindings_ColorPaletteTexture)]]
                                  )
{
    Fragment out;

    float4 modelVertex = transforms.modelView * float4(float3(in.position), 1.0);
    out.position = transforms.projection * modelVertex;
    out.modelPosition = float3(modelVertex) / modelVertex.w;
    out.interpolatedNormal = transforms.modelNormal * float3(in.normal);
    //    out.textureCoordinate = float2(in.textureCoordinate);
    out.color = float4(colorPalette.read(in.colorIndex).rgb, 1);
    return out;
}

fragment float4 VoxelFragmentShader(Fragment in [[stage_in]],
    constant BlinnPhongLightingModelArgumentBuffer &lightingModel [[buffer(VoxelsBindings_BlinnPhongLightingModelArgumentBuffer)]]
)
{
//    float3 ambientColor = in.color.xyz;
//    float3 diffuseColor = float3(0, 0, 0);
//    float3 specularColor = float3(0, 0, 0);
//    float shininess = 16;
//    float3 color = CalculateBlinnPhong(in.modelVertex, in.normalInterp, lightingModel.lightCount, lightingModel.lights, shininess, ambientColor, diffuseColor, specularColor);

    float3 color = in.color.xyz;
    return float4(GammaCorrect(color, lightingModel.screenGamma), 1.0);
}
