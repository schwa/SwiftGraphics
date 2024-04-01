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
        .library(name: "Geometry", targets: ["Geometry"]),
        .library(name: "LegacyGraphics", targets: ["LegacyGraphics"]),
        .library(name: "MetalSupport", targets: ["MetalSupport"]),
        .library(name: "MetalSupportUnsafeConformances", targets: ["MetalSupportUnsafeConformances"]),
        .library(name: "Raster", targets: ["Raster"]),
        .library(name: "SIMDSupport", targets: ["SIMDSupport"]),
        .library(name: "Sketches", targets: ["Sketches"]),
        .library(name: "VectorSupport", targets: ["VectorSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
        .package(url: "https://github.com/schwa/ApproximateEquality", from: "0.2.1"),
        //        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
    ],
    targets: [
        .target(name: "Array2D",
                dependencies: [
                    "CoreGraphicsSupport",
                    "Geometry",
                    .product(name: "Algorithms", package: "swift-algorithms"),
                ]),
        .target(name: "CoreGraphicsSupport"),
        .target(name: "Geometry", dependencies: [
            "ApproximateEquality",
            "CoreGraphicsSupport",
        ]),
        .target(name: "LegacyGraphics",
                dependencies: [
                    .product(name: "Algorithms", package: "swift-algorithms"),
                    "CoreGraphicsSupport",
                    "Geometry",
                    "SIMDSupport",
                ]),
        .target(name: "MetalSupport"),
        .target(name: "MetalSupportUnsafeConformances"),
        .target(name: "Raster",
                dependencies: [
                    .product(name: "Algorithms", package: "swift-algorithms"),
                    "Geometry",
                    "LegacyGraphics",
                ]),
        .target(name: "SIMDSupport",
                dependencies: [
                    .product(name: "ApproximateEquality", package: "ApproximateEquality"),
                ]),
        .target(name: "Sketches",
                dependencies: [
                    .product(name: "ApproximateEquality", package: "ApproximateEquality"),
                    "CoreGraphicsSupport",
                    "Geometry",
                    "SIMDSupport",
                    "VectorSupport",
                ]),
        .target(name: "VectorSupport",
                dependencies: [
                    .product(name: "ApproximateEquality", package: "ApproximateEquality"),
                    .product(name: "ApproximateEqualityMacros", package: "ApproximateEquality"),
                    "CoreGraphicsSupport",
                    "SIMDSupport",
                    "Geometry",
                ]),

        .testTarget(name: "SwiftGraphicsTests", dependencies: [
            "Array2D",
            "CoreGraphicsSupport",
            "Geometry",
            "LegacyGraphics",
            "MetalSupport",
            "MetalSupportUnsafeConformances",
            "Raster",
            "SIMDSupport",
            "Sketches",
            "VectorSupport",
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        ]),
    ]
)
