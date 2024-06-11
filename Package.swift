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
        .library(name: "GenericGeometryBase", targets: ["GenericGeometryBase"]),
        .library(name: "MetalSupport", targets: ["MetalSupport"]),
        .library(name: "MetalUnsafeConformances", targets: ["MetalUnsafeConformances"]),
        .library(name: "Projection", targets: ["Projection"]),
        .library(name: "Raster", targets: ["Raster"]),
        .library(name: "RenderKit", targets: ["RenderKit"]),
        .library(name: "RenderKitShaders", targets: ["RenderKitShaders"]),
        .library(name: "Shapes2D", targets: ["Shapes2D"]),
        .library(name: "Shapes3D", targets: ["Shapes3D"]),
        .library(name: "SIMDSupport", targets: ["SIMDSupport"]),
        .library(name: "SIMDSupportUnsafeConformances", targets: ["SIMDSupportUnsafeConformances"]),
        .library(name: "SwiftGraphicsSupport", targets: ["SwiftGraphicsSupport"]),
        .library(name: "MetalUISupport", targets: ["MetalUISupport"]),
        .library(name: "Compute", targets: ["Compute"]),
        .library(name: "SwiftGraphicsDemosSupport", targets: ["SwiftGraphicsDemosSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        .package(url: "https://github.com/schwa/ApproximateEquality", from: "0.2.1"),
        .package(url: "https://github.com/schwa/Everything", from: "1.1.0"),
        .package(url: "https://github.com/schwa/MetalCompilerPlugin", from: "0.0.2"),
        .package(url: "https://github.com/schwa/swiftformats", from: "0.3.3"),
        .package(url: "https://github.com/schwa/SwiftGLTF", branch: "main"),
        .package(url: "https://github.com/schwa/StreamBuilder", branch: "main"),
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
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),

        // MARK: CoreGraphicsSupport

        .target(
            name: "CoreGraphicsSupport",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),

        // MARK: CoreGraphicsUnsafeConformances

        .target(
            name: "CoreGraphicsUnsafeConformances",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),

        // MARK: Earcut

        .target(
            name: "Earcut", dependencies: [
                "earcut_cpp",
            ], swiftSettings: [.interoperabilityMode(.Cxx),
                               .enableUpcomingFeature("StrictConcurrency"),

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
            name: "GenericGeometryBase",
            dependencies: [
                "ApproximateEquality",
                "CoreGraphicsSupport",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),

        // MARK: MetalSupport

        .target(
            name: "MetalSupport",
            dependencies: ["SIMDSupport",],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "MetalUnsafeConformances",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),

        .target(
            name: "MetalUISupport",
            dependencies: [
                "MetalSupport",
                .product(name: "Everything", package: "Everything"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
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
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),

        // MARK: Projection

        .target(
            name: "Projection",
            dependencies: ["SIMDSupport"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),

        // MARK: RenderKit

        .target(
            name: "RenderKitShaders",
            cSettings: [
                .unsafeFlags(["-Wno-incomplete-umbrella"])
            ],
            cxxSettings: [
                .unsafeFlags(["-Wno-incomplete-umbrella"])
            ],
            plugins: [
                // .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
            ]
        ),
        .testTarget(
            name: "RenderKitTests",
            dependencies: [
                "RenderKit",
                "CoreGraphicsSupport",
                "CoreGraphicsUnsafeConformances",
                "MetalUnsafeConformances",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .interoperabilityMode(.Cxx)
            ]
        ),
        .target(
            name: "RenderKit",
            dependencies: [
                "RenderKitShaders",
                "SIMDSupport",
                "MetalSupport",
                "MetalUISupport",
                "SwiftGraphicsSupport",
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ],
            resources: [
                .process("Placeholder.txt"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
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
                .enableUpcomingFeature("StrictConcurrency"),
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
                "Earcut",
                "MetalSupport",
                "Shapes2D",
                "SIMDSupport",
                "SwiftGraphicsSupport",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .interoperabilityMode(.Cxx)
            ]
        ),

        // MARK: SIMDSupport

        .target(
            name: "SIMDSupport",
            dependencies: [
                .product(name: "ApproximateEquality", package: "ApproximateEquality"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .target(name: "SIMDSupportUnsafeConformances",            swiftSettings: [
            .enableUpcomingFeature("StrictConcurrency"),
        ]),
        .testTarget(name: "SIMDSupportTests", dependencies: [
            "SIMDSupport",
        ]),

        // MARK: SwiftGraphicsSupport

        .target(
            name: "SwiftGraphicsSupport",
            dependencies: [
                "SIMDSupport",
                "MetalSupport",
                "RenderKitShaders",
                .product(name: "SwiftFormats", package: "SwiftFormats"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),

        // MARK: TrivialMeshCLI

        .executableTarget(
            name: "TrivialMeshCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Shapes3D",
                "CoreGraphicsUnsafeConformances",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
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
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .interoperabilityMode(.Cxx)
            ]
        ),
        .executableTarget(
            name: "ComputeTool",
            dependencies: [
                "Compute",
                "SwiftGraphicsSupport",
                "MetalUnsafeConformances",
            ],
            resources: [
                .process("BitonicSort.metal"),
                .process("GameOfLife.metal"),
                .process("RandomFill.metal"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .interoperabilityMode(.Cxx)
            ]
        ),

        // MARK: SwiftGraphicsDemosSupport

        .target(
            name: "SwiftGraphicsDemosSupport",
            dependencies: [
                "Array2D",
                "CoreGraphicsSupport",
                "CoreGraphicsUnsafeConformances",
                "Earcut",
                "GenericGeometryBase",
                "MetalSupport",
                "Projection",
                "Raster",
                "RenderKit",
                "RenderKitShaders",
                "Shapes2D",
                "Shapes3D",
                "SIMDSupport",
                "SwiftGraphicsSupport",
                "SIMDSupportUnsafeConformances",
                "SwiftGLTF",
                "StreamBuilder",
                "WrappingHStack",
                "Compute",
                "MetalUnsafeConformances",
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
                .enableUpcomingFeature("StrictConcurrency"),
                .interoperabilityMode(.Cxx),
            ]
        ),
        .testTarget(
            name: "SwiftGraphicsDemosSupportTests",
            dependencies: ["SwiftGraphicsDemosSupport"],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
    ]
)
