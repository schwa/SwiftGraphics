// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SwiftGraphicsDemosSupport",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .macCatalyst(.v17),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "SwiftGraphicsDemosSupport", targets: ["SwiftGraphicsDemosSupport"]),
    ],
    dependencies: [
        .package(path: "../../../../../SwiftGraphics"),
        .package(url: "https://github.com/schwa/SwiftGLTF", branch: "main"),
        .package(url: "https://github.com/schwa/StreamBuilder", branch: "main"),
        .package(url: "https://github.com/ksemianov/WrappingHStack", from: "0.2.0"),
    ],
    targets: [
        .target(
            name: "SwiftGraphicsDemosSupport",
            dependencies: [
                .product(name: "Array2D", package: "SwiftGraphics"),
                .product(name: "CoreGraphicsSupport", package: "SwiftGraphics"),
                .product(name: "CoreGraphicsUnsafeConformances", package: "SwiftGraphics"),
                .product(name: "Earcut", package: "SwiftGraphics"),
                .product(name: "GenericGeometryBase", package: "SwiftGraphics"),
                .product(name: "MetalSupport", package: "SwiftGraphics"),
                .product(name: "MetalSupportUnsafeConformances", package: "SwiftGraphics"),
                .product(name: "Projection", package: "SwiftGraphics"),
                .product(name: "Raster", package: "SwiftGraphics"),
                .product(name: "RenderKit", package: "SwiftGraphics"),
                .product(name: "RenderKitShaders", package: "SwiftGraphics"),
                .product(name: "Shapes2D", package: "SwiftGraphics"),
                .product(name: "Shapes3D", package: "SwiftGraphics"),
                .product(name: "SIMDSupport", package: "SwiftGraphics"),
                .product(name: "SwiftGraphicsSupport", package: "SwiftGraphics"),
                .product(name: "SIMDSupportUnsafeConformances", package: "SwiftGraphics"),
                "SwiftGLTF",
                "StreamBuilder",
                "WrappingHStack",
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
