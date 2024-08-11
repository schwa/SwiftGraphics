#ifdef __METAL_VERSION__

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

float random(float2 p)
{
    float2 K1 = float2(
        23.14069263277926, // e^pi (Gelfond's constant)
         2.665144142690225 // 2^sqrt(2) (Gelfondâ€“Schneider constant)
    );
    return fract( cos( dot(p,K1) ) * 12345.6789 );
}

#endif // __METAL_VERSION__
