// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftGraphics",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .macCatalyst(.v17),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "Array2D", targets: ["Array2D"]),
        .library(name: "CoreGraphicsSupport", targets: ["CoreGraphicsSupport"]),
        .library(name: "earcut", targets: ["earcut"]),
        .library(name: "Geometry", targets: ["Geometry"]),
        .library(name: "LegacyGraphics", targets: ["LegacyGraphics"]),
        .library(name: "MetalSupport", targets: ["MetalSupport"]),
        .library(name: "MetalSupportUnsafeConformances", targets: ["MetalSupportUnsafeConformances"]),
        .library(name: "Raster", targets: ["Raster"]),
        .library(name: "SIMDSupport", targets: ["SIMDSupport"]),
        .library(name: "SIMDSupportUnsafeConformances", targets: ["SIMDSupportUnsafeConformances"]),
        .library(name: "Sketches", targets: ["Sketches"]),
        .library(name: "VectorSupport", targets: ["VectorSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/schwa/ApproximateEquality", from: "0.2.1"),
    ],
    targets: [
        .target(name: "Array2D",
                dependencies: [
                    "CoreGraphicsSupport",
                    "Geometry",
                    .product(name: "Algorithms", package: "swift-algorithms"),
                ]),
        .target(name: "CoreGraphicsSupport"),
        .target(name: "earcut",
                dependencies: ["earcut_cpp"],
                swiftSettings: [.interoperabilityMode(.Cxx)]
               ),
        .target(name: "earcut_cpp",
                exclude: ["earcut.hpp/test", "earcut.hpp/glfw"]
               ),
        .target(name: "Geometry", dependencies: [
            "ApproximateEquality",
            "CoreGraphicsSupport",
        ]),
        .target(name: "LegacyGraphics",
                dependencies: [
                    .product(name: "Algorithms", package: "swift-algorithms"),
                    "CoreGraphicsSupport",
                    "Geometry",
                    "SIMDSupport",
                ]),
        .target(name: "MetalSupport"),
        .target(name: "MetalSupportUnsafeConformances"),
        .target(name: "Raster",
                dependencies: [
                    .product(name: "Algorithms", package: "swift-algorithms"),
                    "Geometry",
                    "LegacyGraphics",
                ]),
        .target(name: "SIMDSupport",
                dependencies: [
                    .product(name: "ApproximateEquality", package: "ApproximateEquality"),
                ]),
        .target(name: "SIMDSupportUnsafeConformances"),
        .target(name: "Sketches",
                dependencies: [
                    .product(name: "ApproximateEquality", package: "ApproximateEquality"),
                    "CoreGraphicsSupport",
                    "Geometry",
                    "SIMDSupport",
                    "VectorSupport",
                ]),
        .target(name: "VectorSupport",
                dependencies: [
                    .product(name: "ApproximateEquality", package: "ApproximateEquality"),
                    .product(name: "ApproximateEqualityMacros", package: "ApproximateEquality"),
                    "CoreGraphicsSupport",
                    "SIMDSupport",
                    "Geometry",
                ]),
        
        .testTarget(name: "earcuttests", dependencies: [
            "earcut",
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .testTarget(name: "LegacyGraphicsTests", dependencies: [
            "LegacyGraphics",
        ]),
        .testTarget(name: "SIMDSupportTests", dependencies: [
            "SIMDSupport",
        ]),
        .testTarget(name: "SketchesTests", dependencies: [
            "Sketches",
        ]),
        .testTarget(name: "VectorSupportTests", dependencies: [
            "VectorSupport",
        ]),
    ]
)
