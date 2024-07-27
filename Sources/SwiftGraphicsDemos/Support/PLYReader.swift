import BaseSupport
import Everything
import Foundation

public struct Ply {
    public struct Header {
        enum Format: String {
            case ascii
            case binaryLittleEndian = "binary_little_endian"
        }
        struct Element: Equatable {
            enum Specification: Equatable {
                struct Property: Equatable {
                    var name: String
                    var valueType: ScalarType
                }
                struct List: Equatable {
                    var name: String
                    var countType: ScalarType
                    var valueType: ScalarType
                }
                case compound([Property])
                case list(List)
            }

            var name: String
            var count: Int
            var specification: Specification
        }

        var format: Format
        var version: String
        var elements: [Element]
    }

    struct Element {
        enum Record {
            case compound([ScalarValue]) // Values may be different
            case collection([ScalarValue]) // All values are same
        }

        var definition: Header.Element
        var records: [Record]
    }

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

    enum ScalarValue {
        case char(Int8)
        case uchar(UInt8)
        case short(Int16)
        case ushort(UInt16)
        case int(Int32)
        case uint(UInt32)
        case float(Float)
        case double(Double)
    }

    var header: Header

    var elementData: Data

    var processedElements: [Element]?

    var elements: [Element] {
        mutating get throws {
            if let processedElements {
                return processedElements
            }
            else {
                var scanner = CollectionScanner(elements: elementData)
                let elements = try header.elements.map { definition in
                    guard let element = try scanner.scanPLYElement(definition: definition, format: header.format) else {
                        throw BaseError.extended(BaseError.parsingFailure, "Failed to scan element data.")
                    }
                    return element
                }
                processedElements = elements
                return elements
            }
        }
    }

    public init(data: Data, processElements: Bool = false) throws {
        var scanner = CollectionScanner(elements: data)

        guard let header = try scanner.scanPLYHeader() else {
            throw BaseError.extended(BaseError.parsingFailure, "Failed to scan ply header.")
        }
        self.header = header
        self.elementData = data[scanner.current ..< data.endIndex]
        if processElements {
            _ = try self.elements
        }
    }

    @available(*, unavailable)
    func fetch(element: Header.Element, record: Int) -> Data.SubSequence {
        // header.elements.firstIndex(of: element)

        BaseSupport.unimplemented()
    }
}

extension Ply {
    init(string: String, processElements: Bool = false) throws {
        guard let data = string.data(using: .utf8) else {
            throw BaseError.extended(BaseError.encodingFailure, "Could not encode string.")
        }
        try self.init(data: data, processElements: processElements)
    }

    init(url: URL, processElements: Bool = false) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data, processElements: processElements)
    }
}

// MARK: -

// extension Ply.Header.Element {
//    var size: Int {
//
//
//    }
// }

// extension Ply.Header.Element.Property {
//    var size: Int? {
//        switch self {
//        case .list:
//            // Can't compute the length of a list record just from the header :-(
//            nil
//        case .scalar(_, let valueType):
//            valueType.size
//        }
//    }
// }

extension Ply.ScalarType {
    var size: Int {
        switch self {
        // TODO; sizeof()
        case .char:
            1
        case .uchar:
            1
        case .short:
            2
        case .ushort:
            2
        case .int:
            4
        case .uint:
            4
        case .float:
            4
        case .double:
            8
        }
    }
}

// MARK:

// extension Ply.Header.Element: CustomDebugStringConvertible {
//    var debugDescription: String {
//        "Element(name: \(name), properties: \(properties))"
//    }
// }

// extension Ply.Header.Element.Property: CustomDebugStringConvertible {
//    var debugDescription: String {
//        switch self {
//        case .list(name: let name, countType: let countType, valueType: let valueType):
//            return "Property(name: \(name), countType: \(countType) valueType: \(valueType))"
//        case .scalar(name: let name, valueType: let valueType):
//            return "Property(name: \(name), valueType: \(valueType))"
//        }
//    }
// }

extension Ply.Element: CustomDebugStringConvertible {
    var debugDescription: String {
        "Element(name: \(definition.name), records: [\(records.map { "[\($0)]" }.joined(separator: ", "))])"
    }
}

extension Ply.Element.Record: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .collection(let values):
            values.map(\.debugDescription).joined(separator: ", ")
        case .compound(let values):
            values.map(\.debugDescription).joined(separator: ", ")
        }
    }
}

extension Ply.ScalarValue: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .char(let value):
            String(value)
        case .uchar(let value):
            String(value)
        case .short(let value):
            String(value)
        case .ushort(let value):
            String(value)
        case .int(let value):
            String(value)
        case .uint(let value):
            String(value)
        case .float(let value):
            String(value)
        case .double(let value):
            String(value)
        }
    }
}

extension Ply.ScalarValue {
    init?(type: Ply.ScalarType, string: String) {
        switch type {
        case .char:
            guard let value = Int8(string) else {
                return nil
            }
            self = .char(value)
        case .uchar:
            guard let value = UInt8(string) else {
                return nil
            }
            self = .uchar(value)
        case .short:
            guard let value = Int16(string) else {
                return nil
            }
            self = .short(value)
        case .ushort:
            guard let value = UInt16(string) else {
                return nil
            }
            self = .ushort(value)
        case .int:
            guard let value = Int32(string) else {
                return nil
            }
            self = .int(value)
        case .uint:
            guard let value = UInt32(string) else {
                return nil
            }
            self = .uint(value)
        case .float:
            guard let value = Float(string) else {
                return nil
            }
            self = .float(value)
        case .double:
            guard let value = Double(string) else {
                return nil
            }
            self = .double(value)
        }
    }
}

extension Ply.ScalarValue {
    var int: Int? {
        switch self {
        case .char(let value):
            return Int(value)
        case .uchar(let value):
            return Int(value)
        case .short(let value):
            return Int(value)
        case .ushort(let value):
            return Int(value)
        case .int(let value):
            return Int(value)
        case .uint(let value):
            return Int(value)
        case .float(let value):
            return Int(value)
        case .double(let value):
            return Int(value)
        }
    }

    var float: Float? {
        if case let .float(float) = self {
            return float
        }
        return nil
    }
}

extension Ply.Header.Element.Specification {
    var properties: [Ply.Header.Element.Specification.Property]? {
        guard case let .compound(array) = self else {
            return nil
        }
        return array
    }
}

// extension Ply.Header.Element.Property {
//    var name: String {
//        switch self {
//        case .list(name: let name, _, _):
//            return name
//        case .scalar(name: let name, _):
//            return name
//        }
//    }
// }

public extension Ply.Header {
    init(source: String) throws {
        guard let data = source.data(using: .utf8) else {
            throw BaseError.extended(BaseError.encodingFailure, "Could not convert data.")
        }
        var scanner = CollectionScanner(elements: data)
        guard let header = try scanner.scanPLYHeader() else {
            throw BaseError.extended(BaseError.parsingFailure, "Could not scan PLY header")
        }
        self = header
    }
}

extension Ply.Element.Record {
    var values: [Ply.ScalarValue] {
        switch self {
        case .collection(let values):
            return values
        case .compound(let values):
            return values
        }
    }

    func to(definition: Ply.Header.Element, ofType: SIMD3<Float>.Type) -> SIMD3<Float>? {
        guard case let .compound(values) = self else {
            return nil
        }
        guard let x = values[0].float, let y = values[1].float, let z = values[2].float else {
            return nil
        }
        return [x, y, z]
    }
}

extension Ply {
    var points: [SIMD3<Float>] {
        mutating get throws {
            let elements = try self.elements
            return elements[0].records.map {
                $0.to(definition: elements[0].definition, ofType: SIMD3<Float>.self)!
            }
        }
    }
}

// MARK: -

extension CollectionScanner where Element == UInt8 {
    mutating func scanPLYHeader() throws -> Ply.Header? {
        try scan_ { scanner in
            guard scanner.scanPrefixedLine(prefix: "ply") != nil else {
                throw BaseError.extended(BaseError.parsingFailure, "Data does not start with \"ply\"")
            }
            guard let format = scanner.scanPrefixedLine(prefix: "format") else {
                throw BaseError.extended(BaseError.parsingFailure, "Failed to scan format")
            }
            // TODO: Version can be _anything_
            let pattern = #/^(?<format>(ascii|binary_little_endian))\s+(?<version>.+)\s*$/#
            guard let match = format.firstMatch(of: pattern) else {
                throw BaseError.extended(BaseError.parsingFailure, "Unknown format line.")
            }
            //  ascii 1.0\n

            guard let format = Ply.Header.Format(rawValue: String(match.output.format)) else {
                throw BaseError.extended(BaseError.parsingFailure, "Unknown format.")
            }
            let version = String(match.output.version)
            var elements: [Ply.Header.Element] = []
            while !scanner.atEnd {
                if scanner.scanPrefixedLine(prefix: "comment") != nil {
                    // This block intentionally left blank.
                }
                else if scanner.scanPrefixedLine(prefix: "end_header") != nil {
                    break
                }
                else if let element = try scanner.scanPLYHeaderElement() {
                    elements.append(element)
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
            let pattern = #/^(?<name>[A-Za-z]+)\s+(?<count>\d+)\s*$/#
            guard let match = line.firstMatch(of: pattern) else {
                throw BaseError.extended(BaseError.parsingFailure, "Could not parse element.")
            }
            let name = String(match.output.name)
            guard let count = Int(match.output.count) else {
                throw BaseError.extended(BaseError.parsingFailure, "Could not get count of properties")
            }
            guard let specification = try scanner.scanPLYHeaderElementSpecification() else {
                return nil
            }
            return .init(name: name, count: count, specification: specification)
        }
    }

    mutating func scanPLYHeaderElementSpecification() throws -> Ply.Header.Element.Specification? {
        // TODO: This function is doing too much and is badly written.
        var specification: Ply.Header.Element.Specification?
        specification = try scan_ { scanner in
            guard let line = scanner.scanLine() else {
                return nil
            }
            guard let match = line.firstMatch(of: #/^property\s+list\s+(?<count_type>.+)\s+(?<value_type>.+)\s+(?<name>.+)\s*$/#) else {
                return nil
            }
            guard let countType = Ply.ScalarType(rawValue: String(match.output.count_type)) else {
                throw BaseError.extended(BaseError.parsingFailure, "Unknown scalar type \"\(match.output.count_type)\".")
            }
            guard let valueType = Ply.ScalarType(rawValue: String(match.output.value_type)) else {
                throw BaseError.extended(BaseError.parsingFailure, "Unknown scalar type \"\(match.output.value_type)\".")
            }
            let name = String(match.output.name)
            return .list(.init(name: name, countType: countType, valueType: valueType))
        }
        if let specification {
            return specification
        }
        var saved = current
        specification = try scan_ { scanner in
            var properties: [Ply.Header.Element.Specification.Property] = []
            while !scanner.atEnd {
                saved = scanner.current
                guard let line = scanner.scanLine() else {
                    break
                }
                guard let match = line.firstMatch(of: #/^property\s+(?<value_type>.+)\s+(?<name>.+)\s*$/#) else {
                    break
                }
                let name = String(match.output.name)
                guard let valueType = Ply.ScalarType(rawValue: String(match.output.value_type)) else {
                    throw BaseError.extended(BaseError.parsingFailure, "Unknown scalar type \"\(match.output.value_type)\".")
                }
                properties.append(.init(name: name, valueType: valueType))
            }
            return .compound(properties)
        }
        if let specification {
            current = saved
            return specification
        }
        return nil
    }

    mutating func scanPLYElement(definition: Ply.Header.Element, format: Ply.Header.Format) throws -> Ply.Element? {
        try scan_ { scanner in
            var rows: [Ply.Element.Record] = []
            for _ in 0..<definition.count {
                let row = try scanner.scanPLYRow(definition: definition, format: format)
                rows.append(row)
            }
            return .init(definition: definition, records: rows)
        }
    }

    mutating func scanPLYRow(definition: Ply.Header.Element, format: Ply.Header.Format) throws -> Ply.Element.Record {
        switch definition.specification {
        case .compound(let properties):
            var values: [Ply.ScalarValue] = []
            for property in properties {
                let value = try scanPLYScalarValue(type: property.valueType, format: format)
                values.append(value)
            }
            return .compound(values)
        case .list(let list):
            guard let count = try scanPLYScalarValue(type: list.countType, format: format).int else {
                fatalError("Could not convert count to int.")
            }
            let values = try (0..<count).map { _ in
                try scanPLYScalarValue(type: list.valueType, format: format)
            }
            return .collection(values)
        }
    }

    mutating func scanPLYScalarValue(type: Ply.ScalarType, format: Ply.Header.Format) throws -> Ply.ScalarValue {
        switch format {
        case .ascii:
            guard let word = scanWord(), let scalar = Ply.ScalarValue(type: type, string: word) else {
                throw BaseError.extended(BaseError.parsingFailure, "Could not scan value of type \"\(type)\".")
            }
            return scalar
        case .binaryLittleEndian:
            switch type {
            case .char:
                guard let value = scan(type: Int8.self) else {
                    throw BaseError.parsingFailure
                }
                return .char(value)
            case .uchar:
                guard let value = scan(type: UInt8.self) else {
                    throw BaseError.parsingFailure
                }
                return .uchar(value)
            case .short:
                guard let value = scan(type: Int16.self) else {
                    throw BaseError.parsingFailure
                }
                return .short(value)
            case .ushort:
                guard let value = scan(type: UInt16.self) else {
                    throw BaseError.parsingFailure
                }
                return .ushort(value)
            case .int:
                guard let value = scan(type: Int32.self) else {
                    throw BaseError.parsingFailure
                }
                return .int(value)
            case .uint:
                guard let value = scan(type: UInt32.self) else {
                    throw BaseError.parsingFailure
                }
                return .uint(value)
            case .float:
                guard let value = scan(type: Float.self) else {
                    throw BaseError.parsingFailure
                }
                return .float(value)
            case .double:
                guard let value = scan(type: Double.self) else {
                    throw BaseError.parsingFailure
                }
                return .double(value)
            }
        }
    }
}

// MARK: -

struct Char {
    var byte: UInt8

    var isSpace: Bool {
        Darwin.isspace(Int32(byte)) != 0
    }
}

// MARK: -

extension CollectionScanner {
    mutating func scan_<R>(block: (inout CollectionScanner) throws -> R?) rethrows -> R? {
        var scanner = self
        guard let result = try block(&scanner) else {
            return nil
        }
        self = scanner
        return result
    }
}

extension CollectionScanner where Element == UInt8 {
    var remainingString: String? {
        String(bytes: remaining, encoding: .utf8)
    }

    mutating func scan(string: String) -> Bool {
        scan(value: Array(string.utf8))
    }

    mutating func scanLine() -> String? {
        scan_ { scanner in
            guard let bytes = scanner.scanUpTo(value: 0x0a, consuming: true), let line = String(bytes: bytes, encoding: .utf8) else {
                return nil
            }
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
            _ = scanner.scan { !Char(byte: $0).isSpace }

            return string
        }
    }
}
