import BaseSupport
import Everything
import Foundation
import Metal

struct VolumeData: Sendable {
    var name: String
    var archive: TarArchive
    var size: MTLSize

    init(named name: String, in bundle: Bundle = .main, size: MTLSize) throws {
        self.name = name
        archive = try TarArchive(named: "StanfordVolumeData", in: bundle)
        self.size = size
    }

    func slices() throws -> [[UInt16]] {
        let records = try archive.records.values
            .filter { try $0.filename.hasPrefix("StanfordVolumeData/\(name)/") && $0.fileType == .normalFile }
            .sorted { lhs, rhs in
                let lhs = try Int(URL(filePath: lhs.filename).pathExtension)!
                let rhs = try Int(URL(filePath: rhs.filename).pathExtension)!
                return lhs < rhs
            }
        let slices = try records.map {
            let data = try $0.content
            assert(!data.isEmpty)
            return data
        }
        .map {
            let data = $0.withUnsafeBytes { buffer in
                buffer.bindMemory(to: UInt16.self).map {
                    UInt16(bigEndian: $0)
                }
            }
            // TODO: align data to device.minimumLinearTextureAlignment(for: .r16UInt)
            assert(data.count == size.width * size.height)
            return data
        }
        assert(slices.count == size.depth)
        return slices
    }

    func statistics() throws -> (histogram: [Int], min: UInt16, max: UInt16) {
        var counts = Array(repeating: 0, count: Int(UInt16.max))
        let slices = try slices()
        let values = slices.flatMap { $0 }
        for value in values {
            counts[Int(value)] += 1
        }

        return (histogram: counts, min: values.min()!, max: values.max()!)
    }

    func load() throws -> (MTLDevice) throws -> MTLTexture {
        { device in
            let slices = try slices()
            let textureDescriptor = MTLTextureDescriptor()
            textureDescriptor.textureType = .type3D
            textureDescriptor.pixelFormat = .r16Uint
            textureDescriptor.storageMode = .shared

            textureDescriptor.width = size.width
            textureDescriptor.height = size.height
            textureDescriptor.depth = size.depth
            let texture = try device.makeTexture(descriptor: textureDescriptor).safelyUnwrap(BaseError.resourceCreationFailure)
            // texture.label = directoryURL.lastPathComponent
            let bytesPerRow = size.width * 2
            let bytesPerImage = size.width * size.height * 2
            for (index, slice) in slices.enumerated() {
                let region = MTLRegionMake3D(0, 0, index, size.width, size.height, 1)
                texture.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: slice, bytesPerRow: bytesPerRow, bytesPerImage: bytesPerImage)
            }
            return try device.makePrivateCopy(of: texture)
        }
    }
}

extension VolumeData: CustomDebugStringConvertible {
    var debugDescription: String {
        "VolumeData()"
    }
}
