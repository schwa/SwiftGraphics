diff-SIMDSupport:
    ksdiff Sources/SIMDSupport/ ~/Projects/SIMD-Support/Sources/SIMDSupport
    ksdiff Tests/SIMDSupportTests/ ~/Projects/SIMD-Support/Tests/SIMDSupportTests

sync-SIMDSupport:
    rsync --archive --delete Sources/SIMDSupport/ ~/Projects/SIMD-Support/Sources/SIMDSupport
    rsync --archive --delete Tests/SIMDSupportTests/ ~/Projects/SIMD-Support/Tests/SIMDSupportTests
    git -C ~/Projects/SIMD-Support add .
    git -C ~/Projects/SIMD-Support commit  -m "Sync SIMD-Support with SwiftGraphics"
    git -C ~/Projects/SIMD-Support push

diff-CoreGraphicsSupport:
    ksdiff Sources/CoreGraphicsSupport/ ~/Projects/CoreGraphicsGeometrySupport/Sources/CoreGraphicsGeometrySupport
    ksdiff Tests/CoreGraphicsSupportTests/ ~/Projects/CoreGraphicsGeometrySupport/Tests/CoreGraphicsGeometrySupportTests

build-examples:
    xcodebuild -scheme ProjectionDemo -project Examples/ProjectionDemo/ProjectionDemo.xcodeproj build
    xcodebuild -scheme VectorLaboratory -project Examples/VectorLaboratory/VectorLaboratory.xcodeproj build
