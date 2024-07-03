import CoreGraphicsSupport
import Everything
import Foundation
import MetalKit
import MetalSupport
import Observation
import RenderKit
import simd
import SIMDSupport
import SwiftFormats
import SwiftGraphicsSupport
import SwiftUI
import UniformTypeIdentifiers

@Observable
public class GaussianSplatViewModel {
    public var splatCount: Int
    public var splats: Splats<SplatC>
    public var splatDistances: MTLBuffer

    public init(device: MTLDevice, url: URL) throws {
        let data = try! Data(contentsOf: url)

        let splats: MTLBuffer
        let splatCount: Int
        if url.pathExtension == "splatc" {
            let splatSize = 26
            splatCount = data.count / splatSize
            splats = try device.makeBuffer(data: data, options: .storageModeShared).labelled("Splats")
        }
        else if url.pathExtension == "splat" {
            let splatArray = data.withUnsafeBytes { buffer in
                buffer.withMemoryRebound(to: SplatB.self) { buffer in
                    convert(buffer)
                }
            }
            splats = try device.makeBuffer(bytesOf: splatArray, options: .storageModeShared).labelled("Splats")
            splatCount = splatArray.count
        }
        else {
            fatalError()
        }

        let splatIndicesData = (0 ..< splatCount).map { UInt32($0) }.withUnsafeBytes {
            Data($0)
        }
        let splatIndices = try device.makeBuffer(data: splatIndicesData, options: .storageModeShared).labelled("Splats-Indices")
        splatDistances = device.makeBuffer(length: MemoryLayout<Float>.size * splatCount, options: .storageModeShared)!.labelled("Splat-Distances")
        self.splats = Splats<SplatC>(splatBuffer: splats, indexBuffer: splatIndices)
        self.splatCount = splatCount
    }
}
