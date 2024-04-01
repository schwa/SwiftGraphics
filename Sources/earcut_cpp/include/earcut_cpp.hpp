#pragma once

#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstddef>
#include <limits>
#include <memory>
#include <utility>
#include <vector>

#include <simd/simd.h>
#include "../earcut.hpp/include/mapbox/earcut.hpp"

namespace mapbox {
namespace util {

template <>
struct nth<0, simd_float2> {
    inline static auto get(const simd_float2 &t) {
        return t.x;
    };
};
template <>
struct nth<1, simd_float2> {
    inline static auto get(const simd_float2 &t) {
        return t.y;
    };
};

} // namespace util

using Polygon = std::vector<simd_float2>;
using Polygons = std::vector<Polygon>;
using Indices = std::vector<uint32_t>;

Indices earcut_simd(const Polygons& poly) {
    return earcut(poly);
}

} // namespace mapbox
