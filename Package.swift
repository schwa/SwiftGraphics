// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

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
        .library(name: "BaseSupport", targets: ["BaseSupport"]),
        .library(name: "Compute", targets: ["Compute"]),
        .library(name: "CoreGraphicsSupport", targets: ["CoreGraphicsSupport"]),
        .library(name: "CoreGraphicsUnsafeConformances", targets: ["CoreGraphicsUnsafeConformances"]),
        .library(name: "Counters", targets: ["Counters"]),
        .library(name: "Earcut", targets: ["Earcut"]),
        .library(name: "Fields3D", targets: ["Fields3D"]),
        .library(name: "GaussianSplatDemos", targets: ["GaussianSplatDemos"]),
        .library(name: "GaussianSplatSupport", targets: ["GaussianSplatSupport"]),
        .library(name: "GenericGeometryBase", targets: ["GenericGeometryBase"]),
        .library(name: "MetalSupport", targets: ["MetalSupport"]),
        .library(name: "MetalUISupport", targets: ["MetalUISupport"]),
        .library(name: "MetalUnsafeConformances", targets: ["MetalUnsafeConformances"]),
        .library(name: "Projection", targets: ["Projection"]),
        .library(name: "Raster", targets: ["Raster"]),
        .library(name: "RenderKit", targets: ["RenderKit"]),
        .library(name: "RenderKitSceneGraph", targets: ["RenderKitSceneGraph"]),
        .library(name: "RenderKitShaders", targets: ["RenderKitShaders"]),
        .library(name: "RenderKitShadersLegacy", targets: ["RenderKitShadersLegacy"]),
        .library(name: "RenderKitUISupport", targets: ["RenderKitUISupport"]),
        .library(name: "Shapes2D", targets: ["Shapes2D"]),
        .library(name: "Shapes3D", targets: ["Shapes3D"]),
        .library(name: "Shapes3DTessellation", targets: ["Shapes3DTessellation"]),
        .library(name: "SIMDSupport", targets: ["SIMDSupport"]),
        .library(name: "SIMDUnsafeConformances", targets: ["SIMDUnsafeConformances"]),
        .library(name: "SwiftGraphicsDemos", targets: ["SwiftGraphicsDemos"]),
        .library(name: "SwiftUISupport", targets: ["SwiftUISupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        .package(url: "https://github.com/ksemianov/WrappingHStack", from: "0.2.0"),
        .package(url: "https://github.com/schwa/ApproximateEquality", from: "0.4.0"),
        .package(url: "https://github.com/schwa/Everything", from: "1.1.0"),
        .package(url: "https://github.com/schwa/MetalCompilerPlugin", branch: "jwight/logging"),
        .package(url: "https://github.com/schwa/swiftfields", from: "0.0.1"),
        .package(url: "https://github.com/schwa/swiftformats", from: "0.3.5"),
        .package(url: "https://github.com/schwa/SwiftGLTF", branch: "main"),

        // TODO: https://www.pointfree.co/blog/posts/116-being-a-good-citizen-in-the-land-of-swiftsyntax
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0-latest"),
    ],
    targets: [
        // MARK: Array2D

        .target(
            name: "Array2D",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                "CoreGraphicsSupport",
                "CoreGraphicsUnsafeConformances",
                "GenericGeometryBase",
            ],
            swiftSettings: [
            ]
        ),

        // MARK: CoreGraphicsSupport

        .target(
            name: "CoreGraphicsSupport",
            dependencies: [
                "ApproximateEquality",
                "BaseSupport",
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
                "MetalSupportMacros",
            ],
            swiftSettings: [
            ]
        ),
        .target(
            name: "MetalUnsafeConformances",
            dependencies: [
                "BaseSupport"
            ],
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
            exclude: ["README.md"],
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
                "RenderKitSceneGraph"
            ],
            resources: [
                .process("Bundle.txt"),
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
                "CoreGraphicsUnsafeConformances",
                "CoreGraphicsSupport",
                "MetalSupport",
                "Shapes2D",
                "SIMDSupport",
            ],
            exclude: ["Shapes/README.md"]
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
            name: "Compute"
        ),
        .executableTarget(
            name: "ComputeDemos",
            dependencies: [
                "Compute",
                "MetalSupport",
                "MetalUnsafeConformances",
            ],
            resources: [
                .process("Bundle.txt")
            ],
            plugins: [
                .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
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
                "RenderKitSceneGraph"
            ],
            exclude: [
                "Demos/VolumetricRendererDemoView/README.md",
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
            dependencies: ["SwiftGraphicsDemos"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

        .executableTarget(
            name: "SwiftGraphicsDemosCLI",
            dependencies: [
                "MetalSupport",
                "SwiftGraphicsDemos",
            ],
            resources: [
                .process("Media.xcassets"),
                .copy("CubeBinary.ply"),
                .copy("test-splat.3-points-from-train.ply"),
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

        .target(
            name: "GaussianSplatDemos",
            dependencies: [
                "GaussianSplatSupport",
                "RenderKitUISupport",
                "Counters",
                "Fields3D",
                "RenderKitSceneGraph"
            ],
            resources: [
                .copy("Resources/lastchance.splat"),
                .copy("Resources/train.splat"),
                .copy("Resources/winter_fountain.splat"),
                .copy("Resources/vision_dr.splat"),
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
                "RenderKitSceneGraph"
            ],
            resources: [
                .copy("Bundle.txt")
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
                .product(name: "Everything", package: "Everything"),
            ]
        ),
        .target(
            name: "Counters",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Everything", package: "Everything"),
            ]
        ),
        .macro(
            name: "MetalSupportMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            exclude: ["README.md"]
        ),
        .testTarget(
            name: "MetalSupportTests",
            dependencies: [
                "MetalSupport",
                "MetalUnsafeConformances",
                "BaseSupport",
            ]
        ),
        .testTarget(
            name: "MetalSupportMacrosTests",
            dependencies: [
                "MetalSupportMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "GaussianSplatTests",
            dependencies: [
                "GaussianSplatDemos",
                "GaussianSplatShaders",
                "GaussianSplatSupport",
            ],
            resources: [
                .copy("Resources/lastchance.splat"),
            ]
        ),

        .testTarget(
            name: "CoreGraphicsSupportTests",
            dependencies: [
                "CoreGraphicsSupport",
            ]
        ),

        .testTarget(
            name: "GenericGeometryBaseTests",
            dependencies: [
                "GenericGeometryBase",
            ]
        ),

        .target(
            name: "RenderKitSceneGraph",
            dependencies: [
                "BaseSupport",
                "SIMDSupport",
            ],
            swiftSettings: [
            ]
        ),

        .testTarget(
            name: "RenderKitSceneGraphTests",
            dependencies: [
                "RenderKitSceneGraph",
                "ApproximateEquality"
            ]
        ),


    ],
    swiftLanguageVersions: [.v6]
)
