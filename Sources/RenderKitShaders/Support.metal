#include <metal_stdlib>
#include <simd/simd.h>

#import "include/RenderKitShaders.h"

using namespace metal;

float4 kellyColor(float f) {
    unsigned int colors[] = {
        0xFFB300,    // Vivid Yellow
        0x803E75,    // Strong Purple
        0xFF6800,    // Vivid Orange
        0xA6BDD7,    // Very Light Blue
        0xC10020,    // Vivid Red
        0xCEA262,    // Grayish Yellow
        0x817066,    // Medium Gray
        0x007D34,    // Vivid Green
        0xF6768E,    // Strong Purplish Pink
        0x00538A,    // Strong Blue
        0xFF7A5C,    // Strong Yellowish Pink
        0x53377A,    // Strong Violet
        0xFF8E00,    // Vivid Orange Yellow
        0xB32851,    // Strong Purplish Red
        0xF4C800,    // Vivid Greenish Yellow
        0x7F180D,    // Strong Reddish Brown
        0x93AA00,    // Vivid Yellowish Green
        0x593315,    // Deep Yellowish Brown
        0xF13A13,    // Vivid Reddish Orange
        0x232C16,    // Dark Olive Green
    };
    auto colorCount = 20;
    auto color = colors[int(f * colorCount)];
    auto red =   (color & 0xFF0000) >> 16;
    auto green = (color & 0x00FF00) >> 8;
    auto blue =  (color & 0x0000FF) >> 0;
    return { float(red) / 255.0, float(green) / 255.0, float(blue) / 255.0 };
}

float random(float2 p)
{
    float2 K1 = float2(
        23.14069263277926, // e^pi (Gelfond's constant)
         2.665144142690225 // 2^sqrt(2) (Gelfondâ€“Schneider constant)
    );
    return fract( cos( dot(p,K1) ) * 12345.6789 );
}
