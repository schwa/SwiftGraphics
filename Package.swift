// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftGraphics",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .macCatalyst(.v15),
        .tvOS(.v16),
    ],
    products: [
        .library(name: "Array2D", targets: ["Array2D"]),
        .library(name: "CoreGraphicsSupport", targets: ["CoreGraphicsSupport"]),
        .library(name: "SIMDSupport", targets: ["SIMDSupport"]),
        .library(name: "Sketches", targets: ["Sketches"]),
        .library(name: "Geometry", targets: ["Geometry"]),
        .library(name: "Raster", targets: ["Raster"]),
        .library(name: "LegacyGraphics", targets: ["LegacyGraphics"]),
        .library(name: "VectorSupport", targets: ["VectorSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/schwa/ApproximateEquality", from: "0.2.1"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
//        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .target(name: "Array2D",
            dependencies: [
                "CoreGraphicsSupport",
                "Geometry",
            .product(name: "Algorithms", package: "swift-algorithms"),
            ]
        ),
        .target(name: "CoreGraphicsSupport"),
        .target(name: "Geometry", dependencies: ["ApproximateEquality"]),
        .target(name: "LegacyGraphics",
            dependencies: [
                "CoreGraphicsSupport",
                "SIMDSupport",
                "Geometry",
                "Support"
            ]
        ),
        .target(name: "MetalSupport"),
        .target(name: "MetalSupportUnsafeConformances"),
        .target(name: "Raster",
            dependencies: [
                "Geometry",
                "LegacyGraphics",
                "Support"
            ]
        ),
        .target(name: "SIMDSupport"),
        .target(name: "Sketches",
            dependencies: [
                .product(name: "ApproximateEquality", package: "ApproximateEquality"),
                "CoreGraphicsSupport",
                "SIMDSupport",
                "Geometry",
                "VectorSupport",
            ]
        ),
        .target(name: "Support",
            dependencies: [
                "ApproximateEquality",
                .product(name: "Algorithms", package: "swift-algorithms"),
            ]
        ),
        .target(name: "VectorSupport",
            dependencies: [
                .product(name: "ApproximateEquality", package: "ApproximateEquality"),
                .product(name: "ApproximateEqualityMacros", package: "ApproximateEquality"),
                "CoreGraphicsSupport",
                "SIMDSupport",
                "Geometry",
            ]
        ),
        
        .testTarget(name: "LegacyGraphicsTests", dependencies: ["LegacyGraphics"]),
        .testTarget(name: "MetalSupportTests", dependencies: ["MetalSupport"]),
        .testTarget(name: "SketchesTests", dependencies: ["Sketches"]),
        .testTarget(name: "VectorSupportTests", dependencies: [
            "VectorSupport",
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
        ]),
    ]
)
