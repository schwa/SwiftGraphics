#include <metal_stdlib>
#include <simd/simd.h>

#include "include/Shaders.h"

using namespace metal;

bool rules(uint count, bool alive) {
    if (alive == true && (count == 2 || count == 3)) {
        return true;
    }
    else if (alive == false && count == 3) {
        return true;
    }
    else if (alive == true) {
        return false;
    }
    else {
        return false;
    }
}

kernel void gpuLifeKernelWrap(
    uint2 gid [[thread_position_in_grid]],
    texture2d<uint, access::read> inputTexture [[texture(GPULifeKernelBindings_InputTexture)]],
    texture2d<uint, access::write> outputTexture [[texture(GPULifeKernelBindings_OutputTexture)]]) {

    const int2 inputTextureSize = int2(inputTexture.get_width(), inputTexture.get_height());
    if (int(gid.x) >= inputTextureSize.x || int(gid.y) >= inputTextureSize.y) {
        return;
    }

    const int2 positions[] = {
        int2(-1, -1),
        int2( 0, -1),
        int2(+1, -1),
        int2(-1,  0),
        int2(+1,  0),
        int2(-1, +1),
        int2( 0, +1),
        int2(+1, +1),
    };
    uint count = 0;

    for (int N = 0; N != 8; ++N) {
        int2 position = int2(gid) + positions[N];
        position.x = (position.x + inputTextureSize.x) % inputTextureSize.x;
        position.y = (position.y + inputTextureSize.y) % inputTextureSize.y;
        count += inputTexture.read(uint2(position)).r ? 1 : 0;
    }

    const bool alive = inputTexture.read(gid).r != 0;

    outputTexture.write(rules(count, alive), gid);
}

kernel void gpuLifeKernalNoWrap(
    uint2 gid [[thread_position_in_grid]],
    texture2d<uint, access::read> inputTexture [[texture(GPULifeKernelBindings_InputTexture)]],
    texture2d<uint, access::write> outputTexture [[texture(GPULifeKernelBindings_OutputTexture)]]) {

    const int2 sgid = int2(gid);
    const int2 inputTextureSize = int2(inputTexture.get_width(), inputTexture.get_height());
    if (sgid.x >= inputTextureSize.x || sgid.y >= inputTextureSize.y) {
        return;
    }

    uint count = 0;

    const int2 positions[] = {
        int2(-1, -1),
        int2( 0, -1),
        int2(+1, -1),
        int2(-1,  0),
        int2(+1,  0),
        int2(-1, +1),
        int2( 0, +1),
        int2(+1, +1),
    };


    for (int N = 0; N != 8; ++N) {
        int2 position = sgid + positions[N];

        if (position.x < 0 || position.x >= inputTextureSize.x) {
            continue;
        }
        else if (position.y < 0 || position.y >= inputTextureSize.y) {
            continue;
        }
        count += inputTexture.read(uint2(position)).r ? 1 : 0;
    }

    const bool alive = inputTexture.read(gid).r != 0;

    outputTexture.write(rules(count, alive), gid);
}
