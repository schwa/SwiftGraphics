import AsyncAlgorithms
import BaseSupport
import GaussianSplatShaders
import Metal
import MetalSupport
import os
import simd
import SIMDSupport

public extension SplatCloud where Splat == SplatC {
    convenience init(device: MTLDevice, data: Data) throws {
        let splatArray = data.withUnsafeBytes { buffer in
            buffer.withMemoryRebound(to: SplatB.self) { splats in
                convert_b_to_c(splats)
            }
        }

        let splats = try device.makeTypedBuffer(data: splatArray, options: .storageModeShared).labelled("Splats")
        try self.init(device: device, splats: splats)
    }

    convenience init(device: MTLDevice, url: URL) throws {
        let data = try Data(contentsOf: url)
        if url.pathExtension == "splat" {
            try self.init(device: device, data: data)
        } else {
            throw BaseError.error(.illegalValue)
        }
    }
}
