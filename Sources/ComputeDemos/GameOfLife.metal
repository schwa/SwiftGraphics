#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

constant bool wrap [[function_constant(0)]];

static constant int2 positions[] = {
    int2(-1, -1),
    int2( 0, -1),
    int2(+1, -1),
    int2(-1,  0),
    int2(+1,  0),
    int2(-1, +1),
    int2( 0, +1),
    int2(+1, +1),
};

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

template <typename T, typename V> void gameOfLifeGENERIC(
    uint2 gid,
    texture2d<T, access::read> inputTexture,
    texture2d<T, access::write> outputTexture,
    V clear,
    V set
    )
{
    const int2 sgid = int2(gid);
    const int2 inputTextureSize = int2(inputTexture.get_width(), inputTexture.get_height());
    if (sgid.x >= inputTextureSize.x || sgid.y >= inputTextureSize.y) {
        return;
    }
    uint count = 0;
    for (int N = 0; N != 8; ++N) {
        int2 position = sgid + positions[N];
        if (!wrap) {
            if (position.x < 0 || position.x >= inputTextureSize.x) {
                continue;
            }
            else if (position.y < 0 || position.y >= inputTextureSize.y) {
                continue;
            }
        }
        else {
            position.x = (position.x + inputTextureSize.x) % inputTextureSize.x;
            position.y = (position.y + inputTextureSize.y) % inputTextureSize.y;
        }
        count += inputTexture.read(uint2(position)).r ? 1 : 0;
    }
    const bool alive = inputTexture.read(gid).r != 0;
    outputTexture.write(rules(count, alive), gid);
}


[[kernel]]
void gameOfLife_uint(
    uint2 gid [[thread_position_in_grid]],
    texture2d<uint, access::read> inputTexture [[texture(0)]],
    texture2d<uint, access::write> outputTexture [[texture(1)]])
{
    gameOfLifeGENERIC<uint, uint>(gid, inputTexture, outputTexture, 0, 1);
}

[[kernel]]
void gameOfLife_float4(
    uint2 gid [[thread_position_in_grid]],
    texture2d<float, access::read> inputTexture [[texture(0)]],
    texture2d<float, access::write> outputTexture [[texture(1)]])
{
    gameOfLifeGENERIC<float, float4>(gid, inputTexture, outputTexture, float4(0, 0, 0, 0), float4(1, 1, 1, 1));
}
