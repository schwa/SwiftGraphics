#include <metal_stdlib>
#include "include/GLSLCompat.h"
#include "include/Random.h"
//#include "include/Shaders.h"

using namespace metal;

float2 voronoiNoise(float3 value) {
    float2 baseCell = floor(value.xy);

    float minDistToCell = 10;
    float2 closestCell;
    for(int x=-1; x<=1; x++){
        for(int y=-1; y<=1; y++){
            float2 cell = baseCell + float2(x, y);
            float2 cellPosition = cell + rand2dTo2d(cell);
            float2 toCell = cellPosition - value.xy;
            float distToCell = length(toCell);
            if(distToCell < minDistToCell){
                minDistToCell = distToCell;
                closestCell = cell;
            }
        }
    }
    float random = rand2dTo1d(closestCell);
    return float2(minDistToCell, random);
}

// https://www.ronja-tutorials.com/post/029-tiling-noise/
float3 implVoronoiNoise(float3 value){
    float2 baseCell = floor(value.xy);

    //first pass to find the closest cell
    float minDistToCell = 10;
    float2 toClosestCell;
    float2 closestCell;
    for(int x1=-1; x1<=1; x1++){
        for(int y1=-1; y1<=1; y1++){
            float2 cell = baseCell + float2(x1, y1);
            float2 cellPosition = cell + rand2dTo2d(cell);
            float2 toCell = cellPosition - value.xy;
            float distToCell = length(toCell);
            if(distToCell < minDistToCell){
                minDistToCell = distToCell;
                closestCell = cell;
                toClosestCell = toCell;
            }
        }
    }

    //second pass to find the distance to the closest edge
    float minEdgeDistance = 10;
    for(int x2=-1; x2<=1; x2++){
        for(int y2=-1; y2<=1; y2++){
            float2 cell = baseCell + float2(x2, y2);
            float2 cellPosition = cell + rand2dTo2d(cell);
            float2 toCell = cellPosition - value.xy;

            float2 diffToClosestCell = abs(closestCell - cell);
            bool isClosestCell = diffToClosestCell.x + diffToClosestCell.y < 0.1;
            if(!isClosestCell){
                float2 toCenter = (toClosestCell + toCell) * 0.5;
                float2 cellDifference = normalize(toCell - toClosestCell);
                float edgeDistance = dot(toCenter, cellDifference);
                minEdgeDistance = min(minEdgeDistance, edgeDistance);
            }
        }
    }

    float random = rand2dTo1d(closestCell);

    // distance, "id", edge distance
    return float3(minDistToCell, random, minEdgeDistance);
}

// MARK: -

struct VoronoiNoise {
    float2 size;
    float2 offset;
    short mode;
    texture2d<float, access::write> outputTexture;
};

[[kernel]]
void voronoiNoiseCompute(
    constant VoronoiNoise &argument[[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    auto noise = implVoronoiNoise(float3((float2(gid.x, gid.y) + argument.offset) / argument.size, 0));
    float4 color;
    if (argument.mode == 0) {
        float value = noise.x;
        color = float4(value, value, value, 1);
    }
    else if (argument.mode == 1) {
        color = float4(rand1dTo3d(noise.y), 1);
    }
    else if (argument.mode == 2) {
        float value = noise.z;
        color = float4(value, value, value, 1);
    }
    else if (argument.mode == 3) {
        float value = step(noise.z, 0.05);
        color = float4(value, value, value, 1);
    }
    else {
        color = float4(1, 0, 1, 1);
    }
    argument.outputTexture.write(color, gid);
}
