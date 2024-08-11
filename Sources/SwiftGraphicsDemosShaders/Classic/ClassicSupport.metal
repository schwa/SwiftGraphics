#include <metal_stdlib>
#include <simd/simd.h>
#include "include/Common.h"
#include "include/Support.h"

using namespace metal;

float3 GammaCorrect(float3 color, float screenGamma) {
    // apply gamma correction (assume ambientColor, diffuseColor and specularColor have been linearized, i.e. have no gamma correction in them)
    const float3 colorGammaCorrected = pow(color, float3(1.0 / screenGamma));
    // use the gamma corrected color in the fragment
    return colorGammaCorrected;
}
