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
        .library(name: "LegacyGeometry", targets: ["LegacyGeometry"]),
        .library(name: "LegacyGraphics", targets: ["LegacyGraphics"]),
        .library(name: "MetalSupport", targets: ["MetalSupport"]),
        .library(name: "MetalSupportUnsafeConformances", targets: ["MetalSupportUnsafeConformances"]),
        .library(name: "Raster", targets: ["Raster"]),
        .library(name: "SIMDSupport", targets: ["SIMDSupport"]),
        .library(name: "SIMDSupportUnsafeConformances", targets: ["SIMDSupportUnsafeConformances"]),
        .library(name: "Sketches", targets: ["Sketches"]),
        .library(name: "Shapes2D", targets: ["Shapes2D"]),

        .library(name: "Projection", targets: ["Projection"]),
        .library(name: "LegacyGeometryX", targets: ["LegacyGeometryX"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/schwa/ApproximateEquality", from: "0.2.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .target(name: "Array2D",
            dependencies: [
                "CoreGraphicsSupport",
                "LegacyGeometry",
                .product(name: "Algorithms", package: "swift-algorithms"),
            ]
        ),
        .target(name: "CoreGraphicsSupport"),
        .target(name: "earcut",
            dependencies: ["earcut_cpp"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .target(name: "earcut_cpp", exclude: ["earcut.hpp/test", "earcut.hpp/glfw"]),
        .target(name: "LegacyGeometry", dependencies: [
            "ApproximateEquality",
            "CoreGraphicsSupport",
        ]),
        .target(name: "LegacyGraphics",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                "CoreGraphicsSupport",
                "LegacyGeometry",
                "SIMDSupport",
            ]
        ),
        .target(name: "MetalSupport"),
        .target(name: "MetalSupportUnsafeConformances"),
        .target(name: "Raster",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                "LegacyGeometry",
                "LegacyGraphics",
            ]
        ),
        .target(name: "SIMDSupport",
            dependencies: [
                .product(name: "ApproximateEquality", package: "ApproximateEquality"),
            ]
        ),
        .target(name: "SIMDSupportUnsafeConformances"),
        .target(name: "Sketches",
            dependencies: [
                .product(name: "ApproximateEquality", package: "ApproximateEquality"),
                "CoreGraphicsSupport",
                "LegacyGeometry",
                "SIMDSupport",
                "Shapes2D",
            ]
        ),

        .target(name: "Shapes2D",
            dependencies: [
                .product(name: "ApproximateEquality", package: "ApproximateEquality"),
                .product(name: "ApproximateEqualityMacros", package: "ApproximateEquality"),
                "CoreGraphicsSupport",
                "SIMDSupport",
                "LegacyGeometry",
            ]
        ),

        .testTarget(name: "earcuttests", dependencies: ["earcut"], swiftSettings: [.interoperabilityMode(.Cxx)]),
        .testTarget(name: "SIMDSupportTests", dependencies: ["SIMDSupport"]),
        .testTarget(name: "SketchesTests", dependencies: ["Sketches"]),
        .testTarget(name: "Shapes2DTests", dependencies: ["Shapes2D"]),

        .target(name: "Projection", dependencies: ["SIMDSupport"]),
        .target(name: "LegacyGeometryX",
            dependencies: [
                "earcut",
                "SIMDSupport",
                "CoreGraphicsSupport",
                .product(name: "Algorithms", package: "swift-algorithms"),
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .executableTarget(name: "TrivialMeshCLI",
            dependencies: [
                "LegacyGeometryX",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
    ]
)
