diff-SIMDSupport:
    ksdiff Sources/SIMDSupport/ ~/Projects/SIMD-Support/Sources/SIMDSupport
    ksdiff Tests/SIMDSupportTests/ ~/Projects/SIMD-Support/Tests/SIMDSupportTests


sync-SIMDSupport:
    rsync --archive --delete Sources/SIMDSupport/ ~/Projects/SIMD-Support/Sources/SIMDSupport
    rsync --archive --delete Sources/SIMDSupportTests/ ~/Projects/SIMD-Support/Tests/SIMDSupportTests
    git -C ~/Projects/SIMD-Support add .
    git -C ~/Projects/SIMD-Support commit  -m "Sync SIMD-Support with SwiftGraphicss"
    git -C ~/Projects/SIMD-Support push
