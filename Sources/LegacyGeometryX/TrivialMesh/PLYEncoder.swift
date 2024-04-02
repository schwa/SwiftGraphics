public struct PlyEncoder {
    public typealias Output = String

    public init() {
    }

    public func encodeHeader(to output: inout Output) {
        print("ply", to: &output)
    }

    public func encodeVersion(to output: inout Output) {
        print("format ascii 1.0", to: &output)
    }

    public func encodeComment(_ comment: String, to output: inout Output) {
        print("comment \(comment)", to: &output)
    }

    public enum NumericalType: String {
        case char
        case uchar
        case short
        case ushort
        case int
        case uint
        case float
        case double
    }

    public enum Value {
        case char(Int8)
        case uchar(UInt8)
        case short(Int16)
        case ushort(UInt16)
        case int(Int32)
        case uint(UInt32)
        case float(Float)
        case double(Double)
    }

    public enum Kind {
        case numerical(NumericalType)
        case list(count: NumericalType, element: NumericalType)
    }

//    element vertex 12
//    property float x
//    property float y
//    property float z

    public func encodeElementDefinition(name: String, count: Int, properties: [(Kind, String)], to output: inout Output) {
        print("element \(name) \(count)", to: &output)
        for (kind, name) in properties {
            switch kind {
            case .numerical(let numericType):
                print("property \(numericType.rawValue) \(name)", to: &output)
            case .list(let count, let element):
                print("property list \(count.rawValue) \(element.rawValue) \(name)", to: &output)
            }
        }
    }

    public func encodeEndHeader(to output: inout Output) {
        print("end_header", to: &output)
    }

    public func encodeElement(_ values: [Value], to output: inout Output) {
        print(values.map(\.description).joined(separator: " "), to: &output)
    }

    public func encodeListElement(_ values: [Value], to output: inout Output) {
        print("\(values.count) \(values.map(\.description).joined(separator: " "))", to: &output)
    }
}

public extension PlyEncoder.Kind {
    static let char = Self.numerical(.char)
    static let uchar = Self.numerical(.uchar)
    static let short = Self.numerical(.short)
    static let ushort = Self.numerical(.ushort)
    static let int = Self.numerical(.int)
    static let uint = Self.numerical(.uint)
    static let float = Self.numerical(.float)
    static let double = Self.numerical(.double)
}

extension PlyEncoder.Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .char(let value):
            "\(value)"
        case .uchar(let value):
            "\(value)"
        case .short(let value):
            "\(value)"
        case .ushort(let value):
            "\(value)"
        case .int(let value):
            "\(value)"
        case .uint(let value):
            "\(value)"
        case .float(let value):
            "\(value)"
        case .double(let value):
            "\(value)"
        }
    }
}
