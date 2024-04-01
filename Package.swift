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
        .library(name: "CoreGraphicsSupport", targets: ["CoreGraphicsSupport"]),
        .library(name: "MetalSupport", targets: ["MetalSupport"]),
        .library(name: "MetalSupportUnsafeConformances", targets: ["MetalSupportUnsafeConformances"]),
        .library(name: "SIMDSupport", targets: ["SIMDSupport"]),
        .library(name: "SIMDSupportUnsafeConformances", targets: ["SIMDSupportUnsafeConformances"]),
    ],
    dependencies: [
        .package(url: "https://github.com/schwa/ApproximateEquality", from: "0.2.1"),
    ],
    targets: [
        .target(name: "CoreGraphicsSupport"),
        .target(name: "MetalSupport"),
        .target(name: "MetalSupportUnsafeConformances"),
        .target(name: "SIMDSupport",
                dependencies: [
                    .product(name: "ApproximateEquality", package: "ApproximateEquality"),
                ]),
        .target(name: "SIMDSupportUnsafeConformances"),
        .testTarget(name: "SIMDSupportTests", dependencies: [
            "SIMDSupport",
        ])
    ]
)
