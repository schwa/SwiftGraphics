import AsyncAlgorithms
import BaseSupport
import GaussianSplatShaders
import Metal
import MetalSupport
import os
import simd
import SIMDSupport

public extension SplatCloud where Splat == SplatC {
    convenience init(device: MTLDevice, data: Data, splatLimit: Int? = nil) throws {
        let splatArray = data.withUnsafeBytes { buffer in
            buffer.withMemoryRebound(to: SplatB.self) { splats in
                // NOTE: This is horrendously expensive.
                if let splatLimit, splatLimit < splats.count {
                    print("TODO: Sorting splats in CPU.") // TODO: FIXME - replace with radix sort.
                    let positions = splats.map { SIMD3<Float>($0.position) }
                    // swiftlint:disable:next reduce_into
                    let minimums = positions.reduce([.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude], min)
                    // swiftlint:disable:next reduce_into
                    let maximums = positions.reduce([-.greatestFiniteMagnitude, -.greatestFiniteMagnitude, -.greatestFiniteMagnitude], max)
                    let center = (minimums + maximums) * 0.5
                    let splats = splats.sorted { lhs, rhs in
                        let lhs = SIMD3<Float>(lhs.position).distance(to: center)
                        let rhs = SIMD3<Float>(rhs.position).distance(to: center)
                        return lhs < rhs
                    }
                    return convert_b_to_c(splats.prefix(splatLimit))
                }
                else {
                    return convert_b_to_c(splats)
                }
            }
        }
        let splats = try device.makeTypedBuffer(data: splatArray, options: .storageModeShared).labelled("Splats")
        try self.init(device: device, splats: splats)
    }

    convenience init(device: MTLDevice, url: URL, splatLimit: Int? = nil) throws {
        let data = try Data(contentsOf: url)
        if url.pathExtension == "splat" {
            try self.init(device: device, data: data)
        } else {
            throw BaseError.error(.illegalValue)
        }
    }
}
