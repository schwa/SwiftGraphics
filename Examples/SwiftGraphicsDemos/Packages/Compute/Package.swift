// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Compute",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .macCatalyst(.v17),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "Compute",
                 targets: ["Compute"]),
    ],
    dependencies: [
        .package(path: "/Users/schwa/Projects/SwiftGraphics"),
    ],
    targets: [
        .target(name: "Compute", dependencies: [
            .product(name: "MetalSupport", package: "SwiftGraphics"),
            .product(name: "CoreGraphicsSupport", package: "SwiftGraphics"),
            .product(name: "RenderKit", package: "SwiftGraphics"),
        ]),
        .executableTarget(name: "ComputeTool", dependencies: ["Compute"], resources: [
            .process("BitonicSort.metal"),
            .process("GameOfLife.metal"),
            .process("RandomFill.metal"),
        ]),
    ]
)
