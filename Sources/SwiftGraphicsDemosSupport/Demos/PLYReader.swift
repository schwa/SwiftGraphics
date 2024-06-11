import Everything
import Foundation

// Example usage:

struct Ply {
    struct Header {
        enum Format: String {
            case ascii
        }
        var format: Format
        var version: String
        var elements: [Element]
        struct Element {
            struct Property {
                enum ScalarType: String {
                    case char
                    case uchar
                    case short
                    case ushort
                    case int
                    case uint
                    case float
                    case double
                }

                var name: String
                var type: ScalarType
            }
            var name: String
            var count: Int
            var properties: [Property]
        }
    }

    struct Element {
        struct Row {
            enum Value {
                case float(Float)
            }
            var values: [Value]
        }

        var definition: Header.Element
        var rows: [Row]
    }

    var header: Header
    var elements: [Element]
}

extension Bool {
    func trueOrThrow(_ error: @autoclosure () -> any Error) throws {
        throw error()
    }
}

extension CollectionScanner where Element == UInt8 {
    mutating func scan_<R>(block: (inout CollectionScanner) throws -> R?) rethrows -> R? {
        var scanner = self
        guard let result = try block(&scanner) else {
            return nil
        }
        self = scanner
        return result
    }

    var remainingString: String? {
        String(bytes: remaining, encoding: .utf8)
    }

    mutating func scan(string: String) -> Bool {
        scan(value: Array(string.utf8))
    }

    mutating func scanLine() -> String? {
        scan_ { scanner in
            guard let bytes = scanner.scanUpTo(value: 0x0a), let line = String(bytes: bytes, encoding: .utf8) else {
                return nil
            }
            _ = scanner.scan(count: 1)
            return line
        }
    }

    mutating func scanPrefixedLine(prefix: String) -> String? {
        scan_ { scanner in
            guard scanner.scan(string: prefix) == true, let line = scanner.scanLine() else {
                return nil
            }
            return line.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    mutating func scanWord() -> String? {
        scan_ { scanner in
            guard let bytes = scanner.scan(until: { Char(byte: $0).isSpace }) else {
                return nil
            }
            guard let string = String(bytes: bytes, encoding: .utf8) else {
                return nil
            }
            _ = scanner.scan(until: { !Char(byte: $0).isSpace })

            return string
        }
    }
}

enum PlyError: Error {
    case unknown
}

extension CollectionScanner where Element == UInt8 {
    mutating func scanPLY() throws -> Ply? {
        try scan_ { scanner in
            guard let header = try scanner.scanPLYHeader() else {
                return nil
            }
            var elements: [Ply.Element] = []
            for definition in header.elements {
                guard let element = try scanner.scanPLYElement(definition: definition) else {
                    return nil
                }
                elements.append(element)
            }
            return .init(header: header, elements: elements)
        }
    }

    mutating func scanPLYHeader() throws -> Ply.Header? {
        try scan_ { scanner in
            guard scanner.scanPrefixedLine(prefix: "ply") != nil else {
                return nil
            }
            guard let format = scanner.scanPrefixedLine(prefix: "format") else {
                throw PlyError.unknown
            }
            let pattern = #/(?<format>ascii) (?<version>.+)/#
            guard let match = format.firstMatch(of: pattern) else {
                throw PlyError.unknown
            }
            //  ascii 1.0\n

            guard let format = Ply.Header.Format(rawValue: String(match.output.format)) else {
                throw PlyError.unknown
            }
            let version = String(match.output.version)
            var elements: [Ply.Header.Element] = []
            while true {
                _ = scanner.scanPrefixedLine(prefix: "comment")
                if let element = try scanner.scanPLYHeaderElement() {
                    elements.append(element)
                }
                else if scanner.scanPrefixedLine(prefix: "end_header") != nil {
                    break
                }
            }
            return .init(format: format, version: version, elements: elements)
        }
    }

    mutating func scanPLYHeaderElement() throws -> Ply.Header.Element? {
        try scan_ { scanner in
            guard let line = scanner.scanPrefixedLine(prefix: "element") else {
                return nil
            }
            let pattern = #/(?<name>[A-Za-z]+) (?<count>\d+)/#
            guard let match = line.firstMatch(of: pattern) else {
                throw PlyError.unknown
            }
            let name = String(match.output.name)
            guard let count = Int(match.output.count) else {
                throw PlyError.unknown
            }
            var properties: [Ply.Header.Element.Property] = []
            while true {
                guard let property = try scanner.scanPLYHeaderElementProperty() else {
                    break
                }
                properties.append(property)
            }
            return .init(name: name, count: count, properties: properties)
        }
    }

    mutating func scanPLYHeaderElementProperty() throws -> Ply.Header.Element.Property? {
        try scan_ { scanner in
            guard let line = scanner.scanPrefixedLine(prefix: "property") else {
                return nil
            }
            let pattern = #/(?<type>[A-Za-z]+) (?<name>[A-Za-z]+)/#
            guard let match = line.firstMatch(of: pattern) else {
                throw PlyError.unknown
            }
            let name = String(match.output.name)
            guard let type = Ply.Header.Element.Property.ScalarType(rawValue: String(match.output.type)) else {
                throw PlyError.unknown
            }
            return .init(name: name, type: type)
        }
    }

    mutating func scanPLYElement(definition: Ply.Header.Element) throws -> Ply.Element? {
        try scan_ { scanner in
            var rows: [Ply.Element.Row] = []
            for _ in 0..<definition.count {
                guard let row = try scanner.scanPLYRow(definition: definition) else {
                    throw PlyError.unknown
                }
                rows.append(row)
            }
            return .init(definition: definition, rows: rows)
        }
    }

    mutating func scanPLYRow(definition: Ply.Header.Element) throws -> Ply.Element.Row? {
        try scan_ { scanner in
            var values: [Ply.Element.Row.Value] = []
            for property in definition.properties {
                guard let word = scanner.scanWord() else {
                    return nil
                }
                var value: Ply.Element.Row.Value?
                switch property.type {
                case .float:
                    value = Float(word).map { .float($0) }
                default:
                    throw PlyError.unknown
                }
                guard let value else {
                    throw PlyError.unknown
                }
                values.append(value)
            }
            return .init(values: values)
        }
    }
}

struct Char {
    var byte: UInt8

    var isSpace: Bool {
        Darwin.isspace(Int32(byte)) != 0
    }
}

extension Ply {
    init(source: String) throws {
        var scanner = CollectionScanner(elements: Array(source.utf8))
        guard let ply = try scanner.scanPLY() else {
            fatalError() // TODO
        }
        self = ply
    }

    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        var scanner = CollectionScanner(elements: data)
        guard let ply = try scanner.scanPLY() else {
            fatalError() // TODO
        }
        self = ply
    }
}
