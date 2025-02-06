// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SwiftGraphics",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .macCatalyst(.v18),
        .visionOS(.v2),
    ],
    products: [
        .library(name: "Array2D", targets: ["Array2D"]),
        .library(name: "BaseSupport", targets: ["BaseSupport"]),
        .library(name: "Constraints3D", targets: ["Constraints3D"]),
        .library(name: "CoreGraphicsSupport", targets: ["CoreGraphicsSupport"]),
        .library(name: "CoreGraphicsUnsafeConformances", targets: ["CoreGraphicsUnsafeConformances"]),
        .library(name: "Counters", targets: ["Counters"]),
        .library(name: "Earcut", targets: ["Earcut"]),
        .library(name: "GaussianSplatSupport", targets: ["GaussianSplatSupport"]),
        .library(name: "GenericGeometryBase", targets: ["GenericGeometryBase"]),
        .library(name: "MetalSupport", targets: ["MetalSupport"]),
        .library(name: "MetalUISupport", targets: ["MetalUISupport"]),
        .library(name: "MetalUnsafeConformances", targets: ["MetalUnsafeConformances"]),
        .library(name: "Projection", targets: ["Projection"]),
        .library(name: "RenderKit", targets: ["RenderKit"]),
        .library(name: "RenderKitSceneGraph", targets: ["RenderKitSceneGraph"]),
        .library(name: "RenderKitShaders", targets: ["RenderKitShaders"]),
        .library(name: "RenderKitUISupport", targets: ["RenderKitUISupport"]),
        .library(name: "Shapes2D", targets: ["Shapes2D"]),
        .library(name: "Shapes3D", targets: ["Shapes3D"]),
        .library(name: "Shapes3DTessellation", targets: ["Shapes3DTessellation"]),
        .library(name: "SIMDSupport", targets: ["SIMDSupport"]),
        .library(name: "SIMDUnsafeConformances", targets: ["SIMDUnsafeConformances"]),
        .library(name: "SwiftGraphicsDemos", targets: ["SwiftGraphicsDemos"]),
        .library(name: "SwiftUISupport", targets: ["SwiftUISupport"]),
        .library(name: "Traces", targets: ["Traces"]),
        .library(name: "Widgets3D", targets: ["Widgets3D"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        // TODO: https://www.pointfree.co/blog/posts/116-being-a-good-citizen-in-the-land-of-swiftsyntax
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0-latest"),
        .package(url: "https://github.com/ksemianov/WrappingHStack", from: "0.2.0"),
        .package(url: "https://github.com/schwa/Everything", from: "1.2.0"),
        .package(url: "https://github.com/schwa/MetalCompilerPlugin", branch: "jwight/develop"),
        .package(url: "https://github.com/schwa/swiftfields", from: "0.0.1"),
        .package(url: "https://github.com/schwa/swiftformats", from: "0.3.5"),
        .package(url: "https://github.com/schwa/SwiftGLTF", branch: "main"),
        .package(url: "https://github.com/schwa/ApproximateEquality", from: "0.4.0"),

    ],
    targets: [
        // MARK: Array2D

        .target(name: "Array2D",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                "CoreGraphicsSupport",
                "CoreGraphicsUnsafeConformances",
                "GenericGeometryBase",
            ],
            swiftSettings: [
            ]
        ),

        // MARK: BaseSupport

        .target(name: "BaseSupport",
            dependencies: [
                .product(name: "Everything", package: "Everything"),
            ]
        ),

        // MARK: Constraints3D

        .target(name: "Constraints3D",
            dependencies: [
                "BaseSupport",
                "SIMDSupport",
            ]
        ),

        // MARK: CoreGraphics*

        .target(name: "CoreGraphicsSupport",
            dependencies: [
                "BaseSupport",
            ],
            swiftSettings: [
            ]
        ),
        .testTarget(name: "CoreGraphicsSupportTests",
            dependencies: [
                "CoreGraphicsSupport",
                "CoreGraphicsUnsafeConformances",
            ]
        ),
        .target(name: "CoreGraphicsUnsafeConformances",
            swiftSettings: [
            ]
        ),

        // MARK: Counters

        .target(name: "Counters",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Everything", package: "Everything"),
            ]
        ),

        // MARK: Earcut

        .target(name: "Earcut",
            dependencies: [
                "earcut_cpp",
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
            ]
        ),
        .target(name: "earcut_cpp",
            exclude: ["earcut.hpp/test", "earcut.hpp/glfw"]
        ),
        .testTarget(name: "EarcutTests", dependencies: ["Earcut"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

        // MARK: GaussianSplat*

        .target(name: "GaussianSplatShaders",
            plugins: [
                .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
            ]
        ),
        .target(name: "GaussianSplatSupport",
            dependencies: [
                "Constraints3D",
                "GaussianSplatShaders",
                "RenderKit",
                "RenderKitSceneGraph",
                "Shapes3D",
                .product(name: "SwiftFormats", package: "SwiftFormats"),
                "Traces",
            ],
            resources: [
                .process("Assets.xcassets"),
                .copy("Bundle.txt"),
            ]
        ),
        .testTarget(name: "GaussianSplatTests",
            dependencies: [
                "GaussianSplatShaders",
                "GaussianSplatSupport",
                "Projection",
                "ApproximateEquality"
            ]
        ),

        // MARK: GenericGeometryBase

        .target(name: "GenericGeometryBase",
            dependencies: [
                "BaseSupport",
                "CoreGraphicsSupport",
            ],
            swiftSettings: [
            ]
        ),
        .testTarget(name: "GenericGeometryBaseTests",
            dependencies: [
                "GenericGeometryBase",
            ]
        ),

        // MARK: MetalSupport

        .target(name: "MetalSupport",
            dependencies: [
                "BaseSupport",
                "MetalSupportMacros",
                "SIMDSupport",
            ],
            swiftSettings: [
            ]
        ),
        .macro(name: "MetalSupportMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            exclude: ["README.md"]
        ),
        .testTarget(name: "MetalSupportMacrosTests",
            dependencies: [
                "MetalSupportMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        .testTarget(name: "MetalSupportTests",
            dependencies: [
                "BaseSupport",
                "MetalSupport",
                "MetalUnsafeConformances",
            ]
        ),
        .target(name: "MetalUnsafeConformances",
            dependencies: [
                "BaseSupport"
            ],
            swiftSettings: [
            ]
        ),
        .target(name: "MetalUISupport",
            dependencies: [
                .product(name: "Everything", package: "Everything"),
                "MetalSupport",
            ],
            swiftSettings: [
            ]
        ),

        // MARK: Projection

        .target(name: "Projection",
            dependencies: ["SIMDSupport"],
            swiftSettings: [
            ]
        ),

        // MARK: RenderKit

        .target(name: "RenderKit",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                "BaseSupport",
                "MetalSupport",
                "MetalUISupport",
                "SIMDSupport",
            ],
            resources: [
                .process("Bundle.txt"),
            ],
            swiftSettings: [
            ]
        ),
        .target(name: "RenderKitShaders",
            plugins: [
                 .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
            ]
        ),
        .testTarget(name: "RenderKitTests",
            dependencies: [
                "CoreGraphicsSupport",
                "CoreGraphicsUnsafeConformances",
                "MetalUnsafeConformances",
                "RenderKit",
            ]
        ),
        .target(name: "RenderKitUISupport",
            dependencies: [
                "RenderKitSceneGraph",
                "SwiftUISupport",
            ]
        ),

        // MARK: RenderKitSceneGraph

        .target(name: "RenderKitSceneGraph",
            dependencies: [
                "BaseSupport",
                "MetalSupport",
                "RenderKit",
                "RenderKitShaders",
                "SIMDSupport",
            ],
            swiftSettings: [
            ]
        ),
        .testTarget(name: "RenderKitSceneGraphTests",
            dependencies: [
                "BaseSupport",
                "RenderKitSceneGraph",
            ]
        ),

        // MARK: Shapes2D

        .target(name: "Shapes2D",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                "BaseSupport",
                "CoreGraphicsSupport",
                "GenericGeometryBase",
                "SIMDSupport",
            ],
            swiftSettings: [
            ]
        ),
        .testTarget(name: "Shapes2DTests", dependencies: [
            "CoreGraphicsUnsafeConformances",
            "Shapes2D",
        ]),

        // MARK: Shapes3D

        .target(name: "Shapes3D",
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
        .target(name: "Shapes3DTessellation",
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

        // MARK: SIMD*

        .target(name: "SIMDSupport",
            dependencies: [
                "BaseSupport",
                "CoreGraphicsSupport",
            ],
            swiftSettings: [
            ]
        ),
        .testTarget(name: "SIMDSupportTests", dependencies: [
            "SIMDSupport",
        ]),
        .target(name: "SIMDUnsafeConformances",
            swiftSettings: [
            ]
        ),

        // MARK: SwiftGraphicsDemos

        .target(name: "SwiftGraphicsDemos",
            dependencies: [
                "Array2D",
                "Constraints3D",
                "CoreGraphicsSupport",
                "CoreGraphicsUnsafeConformances",
                "Counters",
                "GaussianSplatSupport",
                "GenericGeometryBase",
                "MetalSupport",
                "MetalUnsafeConformances",
                "Projection",
                "RenderKit",
                "RenderKitSceneGraph",
                "RenderKitShaders",
                "RenderKitUISupport",
                "Shapes2D",
                "Shapes3D",
                "Shapes3DTessellation",
                "SIMDSupport",
                "SIMDUnsafeConformances",
                .product(name: "SwiftFields", package: "swiftfields"),
                "SwiftGLTF",
                "SwiftGraphicsDemosShaders",
                "SwiftUISupport",
                "Traces",
                "Widgets3D",
                "WrappingHStack",
            ],
            exclude: [
                "Demos/VolumetricRendererDemoView/README.md",
            ],
            resources: [
                .copy("Resources/adjectives.txt"),
                .process("Resources/Assets.xcassets"),
                .copy("Resources/Models"),
                .copy("Resources/nouns.txt"),
                .copy("Resources/Output"),
                .copy("Resources/PerseveranceTiles"),
                .copy("Resources/StanfordVolumeData.tar"),
                .copy("Resources/TestcardTiles"),
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
            ]
        ),
        .target(name: "SwiftGraphicsDemosShaders",
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
        .testTarget(name: "SwiftGraphicsDemosTests",
            dependencies: ["SwiftGraphicsDemos"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .executableTarget(name: "SwiftGraphicsDemosCLI",
            dependencies: [
                "MetalSupport",
                "SwiftGraphicsDemos",
            ],
            resources: [
                .copy("CubeBinary.ply"),
                .process("Media.xcassets"),
                .copy("test-splat.3-points-from-train.ply"),
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

        // MARK: SwiftUISupport

        .target(name: "SwiftUISupport",
            dependencies: [
                "BaseSupport",
                .product(name: "Everything", package: "Everything"),
                .product(name: "SwiftFormats", package: "SwiftFormats"),
            ]
        ),

        // MARK: Traces

        .target(name: "Traces",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                "BaseSupport",
            ]
        ),

        // MARK: Widgets3D

        .target(name: "Widgets3D",
            dependencies: [
                "Constraints3D",
                "CoreGraphicsSupport",
                "CoreGraphicsUnsafeConformances",
                "Projection",
                "Shapes2D",
                "SIMDSupport",
                .product(name: "SwiftFormats", package: "SwiftFormats"),
                "SwiftUISupport",
            ],
            swiftSettings: [
            ]
        ),

    ],
    swiftLanguageModes: [.v6]
)
