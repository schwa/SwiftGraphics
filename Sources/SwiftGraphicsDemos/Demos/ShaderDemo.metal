#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

[[stitchable]] half4 shader_demo(float2 position, half4 color, half4 color1, half4 color2, float width, float gap, float2 gradient) {


    float x = position.x / abs(gradient.x);
    float y = position.y / abs(gradient.y);
    float sum = x + y;
    auto test = floor(fmod(float(sum), float(width + gap))) < width;
    return test ? color1 : color2;
}
