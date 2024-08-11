#ifdef __METAL_VERSION__
template<typename T> T srgb_to_linear(T c) {
    if (c <= 0.04045) {
        return c / 12.92;
    }
    else {
        return powr((c + 0.055) / 1.055, 2.4);
    }
}

inline float3 srgb_to_linear(float3 c) {
    return float3(srgb_to_linear(c.x), srgb_to_linear(c.y), srgb_to_linear(c.z));
}

inline float4 srgb_to_linear(float4 c) {
    return float4(srgb_to_linear(c.xyz), c.a);
}

template<typename T> T linear_to_srgb(T c) {
    if (isnan(c)) {
        return 0.0;
    }
    else if (c > 1.0) {
        return 1.0;
    }
    else {
        return (c < 0.0031308f) ? (12.92f * c) : (1.055 * powr(c, 1.0 / 2.4) - 0.055);
    }
}

inline float3 linear_to_srgb(float3 c) {
    return float3(linear_to_srgb(c.x), linear_to_srgb(c.y), linear_to_srgb(c.z));
}

inline float4 linear_to_srgb(float4 c) {
    return float4(linear_to_srgb(c.xyz), c.a);
}
#endif
