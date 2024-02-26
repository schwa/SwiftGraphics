diff-SIMDSupport:
    ksdiff Sources/SIMDSupport ~/Projects/SIMD-Support/Sources/SIMDSupport


sync-SIMDSupport:
    rsync --archive --delete Sources/SIMDSupport/ ~/Projects/SIMD-Support/Sources/SIMDSupport
    git -C ~/Projects/SIMD-Support add .
    git -C ~/Projects/SIMD-Support commit  -m "Sync SIMD-Support with SwiftGraphicss"
    git -C ~/Projects/SIMD-Support push
