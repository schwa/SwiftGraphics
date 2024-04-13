#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

//

template<typename T> T lerp(T from, T to, float value) {
    return from + value * (to - from);
}

#define frac fract
#define vec3 float3

// MARK: -

// Capsule / Line - exact
float sdCapsule(vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

// MARK: -

float circle(float2 samplePosition, float radius) {
    return length(samplePosition) - radius;
}

float rectangle(float2 samplePosition, float2 halfSize){
    float2 componentWiseEdgeDistance = abs(samplePosition) - halfSize;
    float outsideDistance = length(max(componentWiseEdgeDistance, 0));
    float insideDistance = min(max(componentWiseEdgeDistance.x, componentWiseEdgeDistance.y), 0.0);
    return outsideDistance + insideDistance;
}

float2 translate(float2 samplePosition, float2 offset){
    return samplePosition - offset;
}

float2 rotate(float2 samplePosition, float rotation) {
    float angle = rotation * M_PI_F * 2 * -1;
    float sine = sin(angle);
    float cosine = cos(angle);
    return float2(cosine * samplePosition.x + sine * samplePosition.y, cosine * samplePosition.y - sine * samplePosition.x);
}

float2 scale(float2 samplePosition, float scale){
    return samplePosition / scale;
}

// MARK: -

float scene(float2 position, float time) {
//    float2 circlePosition = position;
//    circlePosition = translate(circlePosition, float2(100, 100));
//    circlePosition = rotate(circlePosition, time);
//    float pulseScale = 1 + 0.5 * sin(time * 3.14);
//    circlePosition = scale(circlePosition, pulseScale);
//    float sceneDistance = rectangle(circlePosition, float2(10, 20));


    return sdCapsule(float3(position, 0), { 0, 0, 0 }, { 100, 100, 0 }, 1);

    //return sceneDistance;
}

// MARK: -

[[stitchable]] half4 signed_distance_field_1(float2 position, float time, half4 color1, half4 color2) {

    float _LineDistance = 100;
    float _LineThickness = 100;
    auto _InsideColor = color1;
    auto _OutsideColor = color2;
    float dist = scene(position / 2, time);

    half4 col = lerp(_InsideColor, _OutsideColor, step(0, dist));
    float distanceChange = fwidth(dist) * 0.5;
    float majorLineDistance = abs(frac(dist / _LineDistance + 0.5) - 0.5) * _LineDistance;
    float majorLines = smoothstep(_LineThickness - distanceChange, _LineThickness + distanceChange, majorLineDistance);
    return col * majorLines;
}

[[stitchable]] half4 signed_distance_field_2(float2 position, float time, half4 color1, half4 color2) {

    float dist = scene(position / 2, time);
    half4 col = lerp(color1, color2, step(0, dist));
    return col;
}
