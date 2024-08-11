#ifdef __METAL_VERSION__

#import "GLSLCompat.h"

using namespace glslCompatible;

// https://www.ronja-tutorials.com/post/024-white-noise/

//get a scalar random value from a 3d value
inline float rand3dTo1d(float3 value, float3 dotDir = float3(12.9898, 78.233, 37.719)){
    //make value smaller to avoid artefacts
    float3 smallValue = sin(value);
    //get scalar value from 3d vector
    float random = dot(smallValue, dotDir);
    //make value more random by making it bigger and then taking the factional part
    random = frac(sin(random) * 143758.5453);
    return random;
}

inline float rand2dTo1d(float2 value, float2 dotDir = float2(12.9898, 78.233)){
    float2 smallValue = sin(value);
    float random = dot(smallValue, dotDir);
    random = frac(sin(random) * 143758.5453);
    return random;
}

inline float rand1dTo1d(float3 value, float mutator = 0.546){
    float3 random = frac(sin(value + mutator) * 143758.5453);
    return random.x;
}

//to 2d functions

inline float2 rand3dTo2d(float3 value){
    return float2(
                  rand3dTo1d(value, float3(12.989, 78.233, 37.719)),
                  rand3dTo1d(value, float3(39.346, 11.135, 83.155))
                  );
}

inline float2 rand2dTo2d(float2 value){
    return float2(
                  rand2dTo1d(value, float2(12.989, 78.233)),
                  rand2dTo1d(value, float2(39.346, 11.135))
                  );
}

inline float2 rand1dTo2d(float value){
    return float2(
                  rand2dTo1d(value, 3.9812),
                  rand2dTo1d(value, 7.1536)
                  );
}

//to 3d functions

inline float3 rand3dTo3d(float3 value){
    return float3(
                  rand3dTo1d(value, float3(12.989, 78.233, 37.719)),
                  rand3dTo1d(value, float3(39.346, 11.135, 83.155)),
                  rand3dTo1d(value, float3(73.156, 52.235, 09.151))
                  );
}

inline float3 rand2dTo3d(float2 value){
    return float3(
                  rand2dTo1d(value, float2(12.989, 78.233)),
                  rand2dTo1d(value, float2(39.346, 11.135)),
                  rand2dTo1d(value, float2(73.156, 52.235))
                  );
}

inline float3 rand1dTo3d(float value){
    return float3(
                  rand1dTo1d(value, 3.9812),
                  rand1dTo1d(value, 7.1536),
                  rand1dTo1d(value, 5.7241)
                  );
}

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

#endif // __METAL_VERSION__
