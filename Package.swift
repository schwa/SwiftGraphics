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
        .library(name: "Earcut", targets: ["Earcut"]),
        .library(name: "LegacyGeometry", targets: ["LegacyGeometry"]),
        .library(name: "MetalSupport", targets: ["MetalSupport"]),
        .library(name: "MetalSupportUnsafeConformances", targets: ["MetalSupportUnsafeConformances"]),
        .library(name: "Raster", targets: ["Raster"]),
        .library(name: "SIMDSupport", targets: ["SIMDSupport"]),
        .library(name: "SIMDSupportUnsafeConformances", targets: ["SIMDSupportUnsafeConformances"]),
        .library(name: "Sketches", targets: ["Sketches"]),
        .library(name: "Shapes2D", targets: ["Shapes2D"]),
        .library(name: "Shapes3D", targets: ["Shapes3D"]),

        .library(name: "Projection", targets: ["Projection"]),

        .library(name: "RenderKit", targets: ["RenderKit"]),
        .library(name: "RenderKitScratch", targets: ["RenderKitScratch"]),
        .library(name: "RenderKitShaders", targets: ["RenderKitShaders"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        .package(url: "https://github.com/schwa/ApproximateEquality", from: "0.2.1"),
        .package(url: "https://github.com/schwa/Everything", branch: "jwight/downsizing"),
        .package(url: "https://github.com/schwa/MetalCompilerPlugin", from: "0.0.2"),
        .package(url: "https://github.com/schwa/swiftfields", from: "0.1.3"),
        .package(url: "https://github.com/schwa/swiftformats", from: "0.3.3"),
        //        .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")),
        // .package(url: "https://github.com/schwa/StreamBuilder", branch: "main"),

    ],
    targets: [
        .target(name: "Array2D",
                dependencies: [
                    "CoreGraphicsSupport",
                    "LegacyGeometry",
                    .product(name: "Algorithms", package: "swift-algorithms"),
                ]),
        .target(name: "CoreGraphicsSupport"),
        .target(name: "Earcut",
                dependencies: ["earcut_cpp"],
                swiftSettings: [.interoperabilityMode(.Cxx)]),
        .target(name: "earcut_cpp", exclude: ["earcut.hpp/test", "earcut.hpp/glfw"]),
        .target(name: "LegacyGeometry", dependencies: [
            "ApproximateEquality",
            "CoreGraphicsSupport",
        ]),
        .target(name: "MetalSupport"),
        .target(name: "MetalSupportUnsafeConformances"),
        .target(name: "Raster",
                dependencies: [
                    .product(name: "Algorithms", package: "swift-algorithms"),
                    "LegacyGeometry",
                    "CoreGraphicsSupport",
                    "Shapes2D",
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
                    "LegacyGeometry",
                    "SIMDSupport",
                    "Shapes2D",
                ]),
        .target(name: "Shapes2D",
                dependencies: [
                    .product(name: "ApproximateEquality", package: "ApproximateEquality"),
                    .product(name: "ApproximateEqualityMacros", package: "ApproximateEquality"),
                    "CoreGraphicsSupport",
                    "SIMDSupport",
                    "LegacyGeometry",
                    .product(name: "Algorithms", package: "swift-algorithms"),
                ]),

        .testTarget(name: "EarcutTests", dependencies: ["Earcut"], swiftSettings: [.interoperabilityMode(.Cxx)]),
        .testTarget(name: "SIMDSupportTests", dependencies: ["SIMDSupport"]),
        .testTarget(name: "SketchesTests", dependencies: ["Sketches"]),
        .testTarget(name: "Shapes2DTests", dependencies: ["Shapes2D"]),

        .target(name: "Projection", dependencies: ["SIMDSupport"]),
        .target(name: "Shapes3D",
                dependencies: [
                    "Earcut",
                    "SIMDSupport",
                    "CoreGraphicsSupport",
                    .product(name: "Algorithms", package: "swift-algorithms"),
                ],
                swiftSettings: [.interoperabilityMode(.Cxx)]),
        .executableTarget(name: "TrivialMeshCLI",
                          dependencies: [
                              "Shapes3D",
                              .product(name: "ArgumentParser", package: "swift-argument-parser"),
                          ],
                          swiftSettings: [.interoperabilityMode(.Cxx)]),

        .target(
            name: "RenderKit",
            dependencies: [
                "CoreGraphicsSupport",
                "MetalSupport",
                "MetalSupportUnsafeConformances",
                "Shapes2D",
                "SIMDSupport",
                .product(name: "Everything", package: "Everything"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "SwiftFields", package: "swiftfields"),
                .product(name: "SwiftFormats", package: "swiftformats"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                "RenderKitShaders",
                //                .product(name: "StreamBuilder", package: "StreamBuilder"),
            ],
            resources: [
                //                .process("Media.xcassets"),
                .process("VisionOS/Assets.xcassets"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("VariadicGenerics"),
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .target(
            name: "RenderKitShaders",
            plugins: [
                //                .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
            ]
        ),
        .target(
            name: "RenderKitScratch",
            dependencies: [
                "Everything",
                "RenderKit",
            ]
        ),
        .testTarget(
            name: "RenderKitTests",
            dependencies: ["RenderKit", "RenderKitScratch"]
        ),

        //        .executableTarget(
        //            name: "Shapes2DBenchmarkTarget",
        //            dependencies: [
        //                "Shapes2D",
        //                "CoreGraphicsSupport",
        //                .product(name: "Benchmark", package: "package-benchmark"),
        //            ],
        //            path: "Benchmarks/Shapes2DBenchmarkTarget",
        //            plugins: [
        //                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
        //            ]
        //        ),
    ]
)
