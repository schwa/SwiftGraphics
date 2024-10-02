prepare:
    git submodule update --init --recursive

build-package:
    swift package clean
    swift build --configuration debug
    swift build --configuration release
    swift test

build-examples:
    xcodebuild -scheme SwiftGraphicsDemos -project Examples/SwiftGraphicsDemos/SwiftGraphicsDemos.xcodeproj clean
    xcodebuild -scheme SwiftGraphicsDemos -project Examples/SwiftGraphicsDemos/SwiftGraphicsDemos.xcodeproj -destination 'platform=OS X' -skipPackagePluginValidation build
    xcodebuild -scheme SwiftGraphicsDemos -project Examples/SwiftGraphicsDemos/SwiftGraphicsDemos.xcodeproj -destination 'generic/platform=iOS' -skipPackagePluginValidation  build

build-all: build-package build-examples

lint-fix:
    swiftlint lint --fix

benchmark:
    swift package benchmark --target Shapes2DBenchmarkTarget

# plot-benchmark:
#     swift package benchmark --target Shapes2DBenchmarkTarget run --filter InternalUTCClock-now --metric wallClock --format histogramPercentiles

periphery-scan:
    clear
    swift package clean
    periphery scan

periphery-clean-up:
    periphery scan --auto-remove \
        --retain-unused-protocol-func-params \
        --retain-swift-ui-previews \
        --retain-codable-properties \
        --retain-files \
            'Sources/Array2D/*' \
            'Sources/BaseSupport/*' \
            'Sources/Constraints3D/*' \
            'Sources/CoreGraphicsSupport/*' \
            'Sources/CoreGraphicsUnsafeConformances/*' \
            'Sources/Counters/*' \
            'Sources/Earcut/*' \
            'Sources/earcut_cpp/*' \
            'Sources/GaussianSplatShaders/*' \
            'Sources/GaussianSplatSupport/*' \
            # 'Sources/GenericGeometryBase/*' \
            'Sources/MetalSupport/*' \
            'Sources/MetalSupportMacros/*' \
            'Sources/MetalUISupport/*' \
            'Sources/MetalUnsafeConformances/*' \
            'Sources/Projection/*' \
            'Sources/RenderKit/*' \
            'Sources/RenderKitSceneGraph/*' \
            'Sources/RenderKitShaders/*' \
            'Sources/RenderKitUISupport/*' \
            'Sources/Shapes2D/*' \
            'Sources/Shapes3D/*' \
            'Sources/Shapes3DTessellation/*' \
            'Sources/SIMDSupport/*' \
            'Sources/SIMDUnsafeConformances/*' \
            'Sources/SwiftGraphicsDemos/*' \
            'Sources/SwiftGraphicsDemosCLI/*' \
            'Sources/SwiftGraphicsDemosShaders/*' \
            'Sources/SwiftGraphicsDemosShadersLegacy/*' \
            'Sources/SwiftUISupport/*' \
            'Sources/Traces/*' \
            'Sources/Widgets3D/*' \
            'Tests/*'
