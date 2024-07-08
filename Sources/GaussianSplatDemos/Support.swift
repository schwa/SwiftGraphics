import Foundation
import GaussianSplatSupport
import Metal
import RenderKit
import UniformTypeIdentifiers

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
    var splats: Splats? {
        content as? Splats
    }
}

extension Splats {
    init(device: MTLDevice, url: URL) throws {
        let data = try Data(contentsOf: url)
        let splats: TypedMTLBuffer<SplatC>
        if url.pathExtension == "splatc" {
            splats = try device.makeTypedBuffer(data: data, options: .storageModeShared).labelled("Splats")
        }
        else if url.pathExtension == "splat" {
            let splatArray = data.withUnsafeBytes { buffer in
                buffer.withMemoryRebound(to: SplatB.self) { buffer in
                    convert_b_to_c(buffer)
                }
            }
            splats = try device.makeTypedBuffer(data: splatArray, options: .storageModeShared).labelled("Splats")
        }
        else {
            fatalError()
        }
        self = try Splats(device: device, splats: splats)
    }
}

extension UTType {
    static let splat = UTType(filenameExtension: "splat")!
    static let splatC = UTType(filenameExtension: "splatc")!
}

extension Splats: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        "Splats()"
    }
}
