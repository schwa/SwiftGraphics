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
