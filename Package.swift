// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftGraphics",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .macCatalyst(.v18),
        .tvOS(.v18),
        .visionOS(.v2),
    ],
    products: [
        .library(name: "Array2D", targets: ["Array2D"]),
        .library(name: "CoreGraphicsSupport", targets: ["CoreGraphicsSupport"]),
        .library(name: "CoreGraphicsUnsafeConformances", targets: ["CoreGraphicsUnsafeConformances"]),
        .library(name: "Earcut", targets: ["Earcut"]),
        .library(name: "Fields3D", targets: ["Fields3D"]),
        .library(name: "GenericGeometryBase", targets: ["GenericGeometryBase"]),
        .library(name: "MetalSupport", targets: ["MetalSupport"]),
        .library(name: "MetalUnsafeConformances", targets: ["MetalUnsafeConformances"]),
        .library(name: "Projection", targets: ["Projection"]),
        .library(name: "Raster", targets: ["Raster"]),
        .library(name: "RenderKit", targets: ["RenderKit"]),
        .library(name: "RenderKitUISupport", targets: ["RenderKitUISupport"]),
        .library(name: "RenderKitShaders", targets: ["RenderKitShaders"]),
        .library(name: "RenderKitShadersLegacy", targets: ["RenderKitShadersLegacy"]),
        .library(name: "Shapes2D", targets: ["Shapes2D"]),
        .library(name: "Shapes3D", targets: ["Shapes3D"]),
        .library(name: "Shapes3DTessellation", targets: ["Shapes3DTessellation"]),
        .library(name: "SIMDSupport", targets: ["SIMDSupport"]),
        .library(name: "SIMDUnsafeConformances", targets: ["SIMDUnsafeConformances"]),
        .library(name: "MetalUISupport", targets: ["MetalUISupport"]),
        .library(name: "Compute", targets: ["Compute"]),
        .library(name: "SwiftGraphicsDemos", targets: ["SwiftGraphicsDemos"]),

        .library(name: "GaussianSplatDemos", targets: ["GaussianSplatDemos"]),
        .library(name: "GaussianSplatSupport", targets: ["GaussianSplatSupport"]),
        .library(name: "SwiftUISupport", targets: ["SwiftUISupport"]),
        .library(name: "BaseSupport", targets: ["SwiftUISupport"]),

    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        .package(url: "https://github.com/schwa/ApproximateEquality", from: "0.2.1"),
        .package(url: "https://github.com/schwa/Everything", from: "1.1.0"),
        .package(url: "https://github.com/schwa/MetalCompilerPlugin", branch: "jwight/develop"),
        .package(url: "https://github.com/schwa/swiftfields", from: "0.0.1"),
        .package(url: "https://github.com/schwa/swiftformats", from: "0.3.5"),
        .package(url: "https://github.com/schwa/SwiftGLTF", branch: "main"),
        .package(url: "https://github.com/ksemianov/WrappingHStack", from: "0.2.0"),

    ],
    targets: [
        // MARK: Array2D

        .target(
            name: "Array2D",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                "CoreGraphicsSupport",
                "GenericGeometryBase",
            ],
            swiftSettings: [
            ]
        ),

        // MARK: CoreGraphicsSupport

        .target(
            name: "CoreGraphicsSupport",
            dependencies: [
                "ApproximateEquality"
            ],
            swiftSettings: [
            ]
        ),

        // MARK: CoreGraphicsUnsafeConformances

        .target(
            name: "CoreGraphicsUnsafeConformances",
            swiftSettings: [
            ]
        ),

        // MARK: Earcut

        .target(
            name: "Earcut",
            dependencies: [
                "earcut_cpp",
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
            ]
        ),
        .target(
            name: "earcut_cpp",
            exclude: ["earcut.hpp/test", "earcut.hpp/glfw"]
        ),
        .testTarget(
            name: "EarcutTests", dependencies: ["Earcut"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

        // MARK: GenericGeometryBase

        .target(
            name: "Fields3D",
            dependencies: [
                "CoreGraphicsSupport",
                "SIMDSupport",
                "SwiftUISupport",
                .product(name: "SwiftFormats", package: "SwiftFormats"),
            ],
            swiftSettings: [
            ]
        ),

        // MARK: GenericGeometryBase

        .target(
            name: "GenericGeometryBase",
            dependencies: [
                "ApproximateEquality",
                "CoreGraphicsSupport",
            ],
            swiftSettings: [
            ]
        ),

        // MARK: MetalSupport

        .target(
            name: "MetalSupport",
            dependencies: [
                "BaseSupport",
                "SIMDSupport",
            ],
            swiftSettings: [
            ]
        ),
        .target(
            name: "MetalUnsafeConformances",
            swiftSettings: [
            ]
        ),

        .target(
            name: "MetalUISupport",
            dependencies: [
                "MetalSupport",
                .product(name: "Everything", package: "Everything"),
            ],
            swiftSettings: [
            ]
        ),

        // MARK: Raster

        .target(
            name: "Raster",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                "CoreGraphicsSupport",
                "GenericGeometryBase",
                "Shapes2D",
            ],
            swiftSettings: [
            ]
        ),

        // MARK: Projection

        .target(
            name: "Projection",
            dependencies: ["SIMDSupport"],
            swiftSettings: [
            ]
        ),

        // MARK: RenderKit

        .target(
            name: "RenderKitShaders",
            plugins: [
                 .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
            ]
        ),
        .target(
            name: "RenderKitShadersLegacy",
            cSettings: [
                .unsafeFlags(["-Wno-incomplete-umbrella"])
            ],
            cxxSettings: [
                .unsafeFlags(["-Wno-incomplete-umbrella"])
            ],
            plugins: [
                  .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
            ]
        ),
        .testTarget(
            name: "RenderKitTests",
            dependencies: [
                "RenderKit",
                "CoreGraphicsSupport",
                "CoreGraphicsUnsafeConformances",
                "MetalUnsafeConformances",
            ]
        ),
        .target(
            name: "RenderKit",
            dependencies: [
                "RenderKitShadersLegacy",
                "SIMDSupport",
                "MetalSupport",
                "MetalUISupport",
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                "BaseSupport",
            ],
            resources: [
                .process("Placeholder.txt"),
            ],
            swiftSettings: [
            ]
        ),
        .target(
            name: "RenderKitUISupport",
            dependencies: [
                "RenderKit",
                "SwiftUISupport",
                "GaussianSplatSupport",
            ]
        ),

        // MARK: Shapes2D

        .target(
            name: "Shapes2D",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "ApproximateEquality", package: "ApproximateEquality"),
                "CoreGraphicsSupport",
                "GenericGeometryBase",
                "SIMDSupport",
            ],
            swiftSettings: [
            ]
        ),
        .testTarget(name: "Shapes2DTests", dependencies: [
            "Shapes2D",
            "CoreGraphicsUnsafeConformances",
        ]),

        // MARK: Shapes3D

        .target(
            name: "Shapes3D",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                "CoreGraphicsSupport",
                "MetalSupport",
                "Shapes2D",
                "SIMDSupport",
            ]
        ),

        .target(
            name: "Shapes3DTessellation",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                "CoreGraphicsSupport",
                "Earcut",
                "Shapes3D",
                "SIMDSupport",
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),

        // MARK: SIMDSupport

        .target(
            name: "SIMDSupport",
            dependencies: [
                "CoreGraphicsSupport",
                .product(name: "ApproximateEquality", package: "ApproximateEquality"),
            ],
            swiftSettings: [
            ]
        ),
        .target(
            name: "SIMDUnsafeConformances",
            swiftSettings: [
            ]
        ),
        .testTarget(name: "SIMDSupportTests", dependencies: [
            "SIMDSupport",
        ]),

        // MARK: TrivialMeshCLI

        .executableTarget(
            name: "TrivialMeshCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Shapes3D",
                "CoreGraphicsUnsafeConformances",
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),

        // MARK: Compute

        .target(
            name: "Compute",
            dependencies: [
                "MetalSupport",
                "MetalUISupport",
                "CoreGraphicsSupport",
            ]
        ),
        .executableTarget(
            name: "ComputeTool",
            dependencies: [
                "Compute",
                "MetalUnsafeConformances",
            ],
            resources: [
                .process("BitonicSort.metal"),
                .process("GameOfLife.metal"),
                .process("RandomFill.metal"),
            ]
        ),

        // MARK: SwiftGraphicsDemos

        .target(
            name: "SwiftGraphicsDemos",
            dependencies: [
                "Array2D",
                "CoreGraphicsSupport",
                "CoreGraphicsUnsafeConformances",
                "GenericGeometryBase",
                "MetalSupport",
                "Projection",
                "Raster",
                "RenderKit",
                "RenderKitShaders",
                "RenderKitShadersLegacy",
                "Shapes2D",
                "Shapes3D",
                "Shapes3DTessellation",
                "SIMDSupport",
                "SIMDUnsafeConformances",
                "SwiftGLTF",
                "WrappingHStack",
                "Compute",
                "MetalUnsafeConformances",
                "Fields3D",
                .product(name: "SwiftFields", package: "swiftfields"),
                "GaussianSplatDemos",
                "RenderKitUISupport",
                "SwiftUISupport",
            ],
            resources: [
                .process("Resources/Assets.xcassets"),
                .copy("Resources/Output"),
                .copy("Resources/PerseveranceTiles"),
                .copy("Resources/Models"),
                .copy("Resources/TestcardTiles"),
                .copy("Resources/adjectives.txt"),
                .copy("Resources/nouns.txt"),
                .copy("Resources/StanfordVolumeData.tar"),
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
            ]
        ),
        .testTarget(
            name: "SwiftGraphicsDemosTests",
            dependencies: ["SwiftGraphicsDemos"]
        ),

        .executableTarget(
            name: "SwiftGraphicsDemosCLI",
            dependencies: [
                "MetalSupport",
                "SwiftGraphicsDemos",
            ],
            resources: [
                .copy("CubeBinary.ply"),
                .copy("test-splat.3-points-from-train.ply"),
            ]
        ),

        .target(
            name: "GaussianSplatDemos",
            dependencies: ["GaussianSplatSupport", "RenderKitUISupport"],
            resources: [
                .copy("Resources/train.splatc"),
                .copy("Resources/6_20_2024.splatc"),
            ]
        ),
        .target(
            name: "GaussianSplatShaders",
            plugins: [
                .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
            ]
        ),
        .target(
            name: "GaussianSplatSupport",
            dependencies: [
                "GaussianSplatShaders",
                "RenderKit",
                "Shapes3D",
            ],
            resources: [
                .copy("Placeholder.txt")
            ]
        ),
        .target(
            name: "SwiftUISupport",
            dependencies: [
                .product(name: "SwiftFormats", package: "SwiftFormats"),
                .product(name: "Everything", package: "Everything"),
                "BaseSupport",
            ]
        ),
        .target(
            name: "BaseSupport",
            dependencies: [
                .product(name: "SwiftFormats", package: "SwiftFormats"),
                .product(name: "Everything", package: "Everything"),
            ]
        ),
    ],
    swiftLanguageVersions: [.v6]
)
