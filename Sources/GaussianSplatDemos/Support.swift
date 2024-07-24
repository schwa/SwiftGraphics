import Foundation
import GaussianSplatSupport
import Metal
import RenderKit
import UniformTypeIdentifiers

// swiftlint:disable force_unwrapping

extension Bundle {
    func urls(withExtension extension: String) throws -> [URL] {
        try FileManager().contentsOfDirectory(at: resourceURL!, includingPropertiesForKeys: nil).filter {
            $0.pathExtension == `extension`
        }
    }
}

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
    var splatsNode: Node {
        get {
            node(for: "splats")!
        }
        set {
            let accessor = accessor(for: "splats")!
            self[accessor: accessor] = newValue
        }
    }
}

extension Node {
    var splats: SplatCloud? {
        content as? SplatCloud
    }
}

public extension SplatCloud {
    init(device: MTLDevice, url: URL, bitsPerPositionScalar: Int? = nil) throws {
        let data = try Data(contentsOf: url)
        let splats: TypedMTLBuffer<SplatC>
        if url.pathExtension == "splatc" {
            splats = try device.makeTypedBuffer(data: data, options: .storageModeShared).labelled("Splats")
        }
        else if url.pathExtension == "splat" {
            let splatArray = data.withUnsafeBytes { buffer in
                buffer.withMemoryRebound(to: SplatB.self) { splats in
                    let splats = if let bitsPerPositionScalar {
                        splats.downsamplePositions(bits: bitsPerPositionScalar).downsampleScale(bits: bitsPerPositionScalar).downsampleColor()
                    }
                    else {
                        Array(splats)
                    }
                    return convert_b_to_c(splats)
                }
            }
            splats = try device.makeTypedBuffer(data: splatArray, options: .storageModeShared).labelled("Splats")
        }
        else {
            fatalError()
        }
        try self.init(device: device, splats: splats)
    }
}

extension UTType {
    static let splat = UTType(filenameExtension: "splat")!
    static let splatC = UTType(filenameExtension: "splatc")!
}

extension SplatCloud: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        "Splats()"
    }
}
