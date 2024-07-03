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
    public var splats: Splats<SplatC>
    public var cameraTransform: Transform = .translation([0, 0, 3])
    public var cameraProjection: Projection = .perspective(.init())
    public var modelTransform = Transform.identity.rotated(angle: .degrees(180), axis: [1, 0, 0])
    public var debugMode: Bool = false
    public var sortRate: Int = 10

    public init(device: MTLDevice, url: URL) throws {
        let data = try Data(contentsOf: url)
        let splats: TypedMTLBuffer<SplatC>
        if url.pathExtension == "splatc" {
            splats = try device.makeTypedBuffer(data: data, options: .storageModeShared).labelled("Splats")
        }
        else if url.pathExtension == "splat" {
            let splatArray = data.withUnsafeBytes { buffer in
                buffer.withMemoryRebound(to: SplatB.self) { buffer in
                    convert(buffer)
                }
            }
            splats = try device.makeTypedBuffer(data: splatArray, options: .storageModeShared).labelled("Splats")
        }
        else {
            fatalError()
        }
        self.splats = try Splats<SplatC>(device: device, splats: splats)
    }
}
