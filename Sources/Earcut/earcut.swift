@_implementationOnly import earcut_cpp
import simd

// https://github.com/mapbox/earcut.hpp
// https://www.swift.org/documentation/cxx-interop
// https://www.swift.org/documentation/cxx-interop/project-build-setup
// https://forums.swift.org/t/c-interop-mode-not-creating-headers-from-swift-package-manager/68170

public func earcut(polygons: [[SIMD2<Float>]]) -> [UInt32] {
    var cpp_polygons = mapbox.Polygons()
    for polygon in polygons {
        var cpp_polygon = mapbox.Polygon()
        for vertex in polygon {
            cpp_polygon.push_back(vertex)
        }
        cpp_polygons.push_back(cpp_polygon)
    }
    let indices: mapbox.Indices = mapbox.earcut_simd(cpp_polygons)
    // VisionOS SDK doesn't seem to have a way to auto-convert a C++ std::vector into a Swift.Array.
    #if os(visionOS)
    return (0 ..< indices.size()).map { indices[$0] }
    #else
    return Array(indices)
    #endif
}
