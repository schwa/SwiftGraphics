import Foundation

// https://en.wikipedia.org/wiki/Tar_(computing)
public struct TarArchive {
    enum Error: Swift.Error {
        case generic(String)
    }

    public struct Header <Buffer> where Buffer: DataProtocol, Buffer.Index == Int {
        internal var buffer: Buffer
    }

    public private(set) var records: [String: Header<Data>]

    public init(url: URL) throws {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        guard data.count >= 2048 else {
            throw Error.generic("Tar archives need to be at least 2048 bytes.")
        }
        var remainingRange = data.startIndex ..< data.endIndex
        var records: [String: Header<Data>] = [:]
        while remainingRange.count > 1024 {
            if remainingRange.count < 512 {
                throw Error.generic("Not enough data remaining to read a header record.")
            }
            var header = Header(buffer: data[remainingRange])
            let length = try header.totalLength
            header = Header(buffer: data[remainingRange])
            remainingRange = remainingRange.startIndex + length ..< data.endIndex
            records[try header.filename] = header
        }
        self.records = records
    }
}

extension TarArchive.Header: CustomStringConvertible {
    public var description: String {
        do {
            return "Header(buffer: \(buffer.startIndex)..<\(buffer.endIndex), filename: \(try filename), filesize: \(try fileSize)"
        }
        catch {
            return "Header(buffer: \(buffer.startIndex)..<\(buffer.endIndex), invalid!)"
        }
    }
}

public extension TarArchive.Header {
    var filename: String {
        get throws {
            let bytes = buffer.sub(offset: 0, count: 100)
            return String(decodingCString: Array(bytes), as: UTF8.self)
        }
    }

    var fileSize: Int {
        get throws {
            let bytes = buffer.sub(offset: 124, count: 12)
            guard let string = String(bytes: bytes, encoding: .nonLossyASCII)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                throw TarArchive.Error.generic("Failed to read file size.")
            }
            guard let result = Int(string, radix: 8) else {
                throw TarArchive.Error.generic("Failed to read file size.")
            }
            return result
        }
    }

    enum FileType: String {
        case normalFile = "0"
        case hardLink = "1"
        case symbolicLink = "2"
        case characterSpecial = "3"
        case directory = "5"
        case fifo = "6"
        case contiguousFile = "7"
        case globalExtendedHeader = "g"
        case extendedHeader = "x"
    }

    var fileType: FileType {
        get throws {
            let bytes = buffer.sub(offset: 156, count: 1)
            guard let string = String(bytes: bytes, encoding: .nonLossyASCII), let fileType = FileType(rawValue: string) else {
                throw TarArchive.Error.generic("Failed to read file type.")
            }
            return fileType
        }
    }

    var content: Buffer.SubSequence {
        get throws {
            buffer.sub(offset: 512, count: try fileSize)
        }
    }

    internal var totalLength: Int {
        get throws {
            return try align(fileSize + 512, alignment: 512)
        }
    }
}

extension TarArchive {
    init(named name: String, in bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: name, withExtension: "tar") else {
            throw Error.generic("Could not construct url for \(name).")
        }
        self = try TarArchive(url: url)
    }
}

// MARK: -

private func align(_ value: Int, alignment: Int) -> Int {
    return (value + alignment - 1) / alignment * alignment
}

private extension DataProtocol where Index == Int {
    func sub(offset: Int, count: Int) -> SubSequence {
        let start = startIndex.advanced(by: offset)
        let end = start.advanced(by: count)
        return self[start..<end]
    }
}
