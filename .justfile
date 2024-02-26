sync-MetalSupport:
    cd Sources/MetalSupport
    rsync --archive --delete . ~/Projects/MetalSupport/Sources/MetalSupport
    cd ~/Projects/MetalSupport
    # git add .
    # git commit -m "Sync MetalSupport"
    # git push

diff-SIMDSupport:
    ksdiff Sources/SIMDSupport ~/Projects/SIMD-Support/Sources/SIMDSupport


sync-SIMDSupport:
    rsync --archive --delete Sources/SIMDSupport ~/Projects/SIMD-Support/Sources/SIMDSupport
    cd ~/Projects/SIMD-Support
    # git add .
    # git commit -m "Sync SIMDSupport"
    # git push
