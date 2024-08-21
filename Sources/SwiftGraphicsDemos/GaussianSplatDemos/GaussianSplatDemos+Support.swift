import BaseSupport
import Foundation
import GaussianSplatSupport
import Metal
import RenderKit
import RenderKitSceneGraph
import UniformTypeIdentifiers

// swiftlint:disable force_unwrapping

// MARK: -

extension Int {
    var toDouble: Double {
        get {
            Double(self)
        }
        set {
            self = Int(newValue)
        }
    }
}

extension SceneGraph {
    // TODO: Rename - `unsafeSplatsNode`
    var splatsNode: Node {
        get {
            let accessor = self.firstAccessor(label: "splats")!
            return self[accessor: accessor]!
        }
        set {
            let accessor = self.firstAccessor(label: "splats")!
            self[accessor: accessor] = newValue
        }
    }
}

public extension SplatCloud where Splat == SplatC {
    init(device: MTLDevice, url: URL, splatLimit: Int? = nil) throws {
        let data = try Data(contentsOf: url)
        let splats: TypedMTLBuffer<SplatC>
        if url.pathExtension == "splat" {
            let splatArray = data.withUnsafeBytes { buffer in
                buffer.withMemoryRebound(to: SplatB.self) { splats in
                    // NOTE: This is horrendously expensive.
                    if let splatLimit, splatLimit < splats.count {
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
            splats = try device.makeTypedBuffer(data: splatArray, options: .storageModeShared).labelled("Splats")
        } else {
            throw BaseError.error(.illegalValue)
        }
        try self.init(device: device, splats: splats)
    }
}

extension UTType {
    static let splat = UTType(filenameExtension: "splat")!
}

extension SplatCloud: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        "Splats()"
    }
}
