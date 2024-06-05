// swift-tools-version: 5.10

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
        .library(name: "CoreGraphicsUnsafeConformances", targets: ["CoreGraphicsUnsafeConformances"]),
        .library(name: "Earcut", targets: ["Earcut"]),
        .library(name: "GenericGeometryBase", targets: ["GenericGeometryBase"]),
        .library(name: "MetalSupport", targets: ["MetalSupport"]),
        .library(name: "MetalSupportUnsafeConformances", targets: ["MetalSupportUnsafeConformances"]),
        .library(name: "Projection", targets: ["Projection"]),
        .library(name: "Raster", targets: ["Raster"]),
        .library(name: "RenderKit", targets: ["RenderKit"]),
        .library(name: "RenderKitShaders", targets: ["RenderKitShaders"]),
        .library(name: "Shapes2D", targets: ["Shapes2D"]),
        .library(name: "Shapes3D", targets: ["Shapes3D"]),
        .library(name: "SIMDSupport", targets: ["SIMDSupport"]),
        .library(name: "SIMDSupportUnsafeConformances", targets: ["SIMDSupportUnsafeConformances"]),
        .library(name: "SwiftGraphicsSupport", targets: ["SwiftGraphicsSupport"]),
        .library(name: "RenderKit4", targets: ["RenderKit4"]),
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
        .package(url: "https://github.com/schwa/swiftfields", from: "0.1.3"),
        .package(url: "https://github.com/schwa/swiftformats", from: "0.3.3"),
        .package(url: "https://github.com/schwa/SwiftGLTF", branch: "main"),
        .package(url: "https://github.com/schwa/StreamBuilder", branch: "main"),
        .package(url: "https://github.com/ksemianov/WrappingHStack", from: "0.2.0"),

        //        .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")),
    ],
    targets: [
        // MARK: Array2D
        .target(
            name: "Array2D",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                "CoreGraphicsSupport",
                "GenericGeometryBase",
            ]
        ),

        // MARK: CoreGraphicsSupport
        .target(name: "CoreGraphicsSupport"),

        // MARK: CoreGraphicsUnsafeConformances
        .target(name: "CoreGraphicsUnsafeConformances"),

        // MARK: Earcut
        .target(
            name: "Earcut", dependencies: [
                "earcut_cpp",
            ], swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .target(name: "earcut_cpp", exclude: ["earcut.hpp/test", "earcut.hpp/glfw"]),
        .target(
            name: "GenericGeometryBase",
            dependencies: [
                "ApproximateEquality",
                "CoreGraphicsSupport",
            ]
        ),
        .testTarget(
            name: "EarcutTests", dependencies: [
                "Earcut",
            ], swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

        // MARK: MetalSupport
        .target(name: "MetalSupport", dependencies: [
            "SIMDSupport",
        ]),
        .target(name: "MetalSupportUnsafeConformances"),
        .target(
            name: "Raster",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                "CoreGraphicsSupport",
                "GenericGeometryBase",
                "Shapes2D",
            ]
        ),

        // MARK: Projection
        .target(name: "Projection", dependencies: [
            "SIMDSupport",
        ]),

        // MARK: RenderKit
        .target(
            name: "RenderKit",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Everything", package: "Everything"),
                .product(name: "SwiftFields", package: "swiftfields"),
                "CoreGraphicsSupport",
                "MetalSupport",
                "RenderKitShaders",
                "Shapes2D",
                "SIMDSupport",
                "MetalUISupport",
            ],
            resources: [
                .process("Assets.xcassets"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("VariadicGenerics"),
                .enableUpcomingFeature("StrictConcurrency"),
                .interoperabilityMode(.Cxx),
            ]
        ),
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
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

        // MARK: Shapes2D

        .target(
            name: "Shapes2D",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "ApproximateEquality", package: "ApproximateEquality"),
                .product(name: "ApproximateEqualityMacros", package: "ApproximateEquality"),
                "CoreGraphicsSupport",
                "GenericGeometryBase",
                "SIMDSupport",
            ]
        ),
        .testTarget(name: "Shapes2DTests", dependencies: [
            "Shapes2D",
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
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

        // MARK: SIMDSupport

        .target(
            name: "SIMDSupport",
            dependencies: [
                .product(name: "ApproximateEquality", package: "ApproximateEquality"),
            ]
        ),
        .target(name: "SIMDSupportUnsafeConformances"),
        .testTarget(name: "SIMDSupportTests", dependencies: [
            "SIMDSupport",
        ]),

        .target(
            name: "SwiftGraphicsSupport",
            dependencies: [
                "SIMDSupport",
                "MetalSupport",
                "RenderKitShaders",
                .product(name: "SwiftFormats", package: "SwiftFormats"),
            ]
        ),

        // MARK: TrivialMeshCLI
        .executableTarget(
            name: "TrivialMeshCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Shapes3D",
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

            .target(
                name: "MetalUISupport",
                dependencies: [
                    "MetalSupport",
                    .product(name: "Everything", package: "Everything"),
                ]
            ),

            .target(
                name: "RenderKit4",
                dependencies: [
                    "RenderKitShaders",
                    "SIMDSupport",
                    "MetalSupport",
                    "MetalUISupport",
                    "SwiftGraphicsSupport",
                ],
                resources: [
                    .process("Placeholder.txt"),
                ]
            ),

        .target(
            name: "Compute",
            dependencies: [
                "MetalSupport",
                "MetalUISupport",
                "CoreGraphicsSupport",
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .executableTarget(
            name: "ComputeTool",
            dependencies: [
                "Compute",
                "SwiftGraphicsSupport",
            ],
            resources: [
                .process("BitonicSort.metal"),
                .process("GameOfLife.metal"),
                .process("RandomFill.metal"),
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

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
                "RenderKit4",
                "MetalSupportUnsafeConformances",
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
                .interoperabilityMode(.Cxx)
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
