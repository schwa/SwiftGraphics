#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

[[stitchable]] half4 my_color_effect(float2 position, half4 color, float t) {
    float size = 4;
    float x = (t * 8) + position.x / size;
    float y = position.y / size;
    float sum = x + y;
    auto test = floor(fmod(float(sum), float(2))) == 0;
    color.a *= test ? 1 : 0.9;
    return color;
}

[[stitchable]] half4 my_color_effect_2(float2 position, half4 color1, half4 color2, float t) {
    float size = 4;
    float x = (t * 8) + position.x / size;
    float y = position.y / size;
    float sum = x + y;
    auto test = floor(fmod(float(sum), float(2))) == 0;
    return test ? color1 : color2;
}
