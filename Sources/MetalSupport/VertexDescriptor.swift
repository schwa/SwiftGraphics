import BaseSupport
import Metal
import MetalKit
import ModelIO

// swiftlint:disable force_unwrapping

public struct VertexDescriptor: Hashable, Sendable {
    public struct Layout: Hashable, Sendable {
        public var label: String?
        public var bufferIndex: Int
        public var stride: Int
        public var stepFunction: MTLVertexStepFunction
        public var stepRate: Int
        public var attributes: [Attribute]

        public init(label: String? = nil, bufferIndex: Int = 0, stride: Int = 0, stepFunction: MTLVertexStepFunction = .perVertex, stepRate: Int = 1, attributes: [Attribute]) {
            assert(bufferIndex >= 0)
            assert(bufferIndex >= 0)
            assert(stride >= 0)
            self.label = label
            self.bufferIndex = bufferIndex
            self.stride = stride
            self.stepFunction = stepFunction
            self.stepRate = stepRate
            self.attributes = attributes
        }
    }

    public struct Attribute: Hashable, Sendable {
        public enum Semantic: Hashable, Sendable {
            case position
            case normal
            case textureCoordinate
            // IDEA: Add in more semantics. (From ModelIO semantics and GLTF etc)
        }

        public var label: String?
        public var semantic: Semantic?
        public var format: MTLVertexFormat
        public var offset: Int

        public init(label: String? = nil, semantic: Semantic?, format: MTLVertexFormat, offset: Int) {
            assert(offset >= 0)
            self.label = label
            self.semantic = semantic
            self.format = format
            self.offset = offset
        }
    }

    public var label: String?
    public var layouts: [Layout]

    public init(label: String? = nil, layouts: [Layout] = []) {
        assert(Set(layouts.map(\.bufferIndex)).count == layouts.count)
        self.label = label
        self.layouts = layouts
    }
}

// MARK: CustomStringConvertible

extension VertexDescriptor: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "VertexDescriptor \(String(describing: label))\n"
        for (index, layout) in layouts.enumerated() {
            s += "\tLayout \(index) \(String(describing: layout.label))\n"
            s += "\t\tstepFunction: \(layout.stepFunction)\n"
            s += "\t\tstride: \(layout.stride)\n"
            s += "\t\tstepRate: \(layout.stepRate)\n"
            s += "\t\tbufferIndex: \(layout.bufferIndex)\n"
            for (index, attribute) in layout.attributes.enumerated() {
                s += "\t\tattribute \(index) \(String(describing: attribute.label))\n"
                s += "\t\t\tsemantic: \(String(describing: attribute.semantic))\n"
                s += "\t\t\toffset: \(attribute.offset)\n"
                s += "\t\t\tformat: \(attribute.format)\n"
            }
        }
        return s
    }
}

// Codable.

extension VertexDescriptor: Encodable {
}

extension VertexDescriptor.Layout: Encodable {
    enum CodingKeys: CodingKey {
        case label
        case bufferIndex
        case stride
        case stepFunction
        case stepRate
        case attributes
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let label {
            try container.encode(label, forKey: .label)
        }
        try container.encode(bufferIndex, forKey: .bufferIndex)
        try container.encode(stride, forKey: .stride)
        if stepFunction != .perVertex {
            try container.encode(stepFunction.stringValue, forKey: .stepFunction)
        }
        if stepRate != 1 {
            try container.encode(stepRate, forKey: .stepRate)
        }
        try container.encode(attributes, forKey: .attributes)
    }
}

extension VertexDescriptor.Attribute: Encodable {
    enum CodingKeys: CodingKey {
        case label
        case semantic
        case format
        case offset
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let label {
            try container.encode(label, forKey: .label)
        }
        if let semantic {
            try container.encode(semantic, forKey: .semantic)
        }
        try container.encode(format.stringValue, forKey: .format)
        if offset != 0 {
            try container.encode(offset, forKey: .offset)
        }
    }
}

extension VertexDescriptor.Attribute.Semantic: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .position:
            try container.encode("position")
        case .normal:
            try container.encode("normal")
        case .textureCoordinate:
            try container.encode("textureCoordinate")
        }
    }
}

// MARK: Utilities

public extension VertexDescriptor {
    mutating func setPackedOffsets() {
        layouts = layouts.map { layout in
            var layout = layout
            var nextOffset = 0
            layout.attributes = layout.attributes.map { attribute in
                let offset = nextOffset
                nextOffset += attribute.format.size
                return .init(semantic: attribute.semantic, format: attribute.format, offset: offset)
            }
            return layout
        }
    }

    mutating func setPackedStrides() {
        layouts = layouts.map { layout in
            var layout = layout
            if let lastAttribute = layout.attributes.last {
                layout.stride = lastAttribute.offset + lastAttribute.format.size
            }
            return layout
        }
    }
}

// MARK: Convert from/to MTLVertexDescriptor

public extension VertexDescriptor {
    init(_ mtlDescriptor: MTLVertexDescriptor) throws {
        // From "Metal feature set tables"
        let maxBufferArgumentEntriesCount = 31
        let maxVertexAttributesCount = 31
        let layouts: [Layout] = (0 ..< maxBufferArgumentEntriesCount).compactMap { bufferIndex in
            let mtlLayout = mtlDescriptor.layouts[bufferIndex]!
            guard mtlLayout.stride != 0 else {
                return nil
            }
            let attributes: [Attribute] = (0 ..< maxVertexAttributesCount).compactMap { index in
                let mtlAttribute = mtlDescriptor.attributes[index]!
                guard mtlAttribute.format != .invalid else {
                    return nil
                }
                guard mtlAttribute.bufferIndex == bufferIndex else {
                    return nil
                }
                return Attribute(semantic: nil, format: mtlAttribute.format, offset: mtlAttribute.offset)
            }
            return Layout(bufferIndex: bufferIndex, stride: mtlLayout.stride, stepFunction: mtlLayout.stepFunction, stepRate: mtlLayout.stepRate, attributes: attributes)
        }
        self = .init(label: nil, layouts: layouts)
    }
}

public extension MTLVertexDescriptor {
    convenience init(_ descriptor: VertexDescriptor) {
        self.init()
        var nextAttributeIndex = 0
        for layout in descriptor.layouts {
            layouts[layout.bufferIndex].stride = layout.stride
            layouts[layout.bufferIndex].stepFunction = layout.stepFunction
            layouts[layout.bufferIndex].stepRate = layout.stepRate
            for attribute in layout.attributes {
                attributes[nextAttributeIndex].format = attribute.format
                attributes[nextAttributeIndex].offset = attribute.offset
                attributes[nextAttributeIndex].bufferIndex = layout.bufferIndex
                nextAttributeIndex += 1
            }
        }
    }
}

// MARK: ModelIO support.

public extension VertexDescriptor {
    init(_ mdlDescriptor: MDLVertexDescriptor) throws {
        // From "Metal feature set tables"
        let maxBufferArgumentEntriesCount = 31
        let maxVertexAttributesCount = 31
        let layouts: [Layout] = try (0 ..< maxBufferArgumentEntriesCount).compactMap { bufferIndex in
            guard let mdlLayout = mdlDescriptor.layouts[bufferIndex] as? MDLVertexBufferLayout else {
                throw BaseError.invalidParameter
            }
            guard mdlLayout.stride != 0 else {
                return nil
            }
            let attributes: [Attribute] = try (0 ..< maxVertexAttributesCount).compactMap { attributeIndex in
                guard let mdlAttribute = mdlDescriptor.attributes[attributeIndex] as? MDLVertexAttribute else {
                    throw BaseError.invalidParameter
                }
                guard mdlAttribute.bufferIndex == bufferIndex, mdlAttribute.format != .invalid else {
                    return nil
                }
                let format = MTLVertexFormat(mdlAttribute.format)
                return Attribute(semantic: nil, format: format, offset: mdlAttribute.offset)
            }
            return .init(label: nil, bufferIndex: bufferIndex, stride: mdlLayout.stride, stepFunction: .perVertex, stepRate: 1, attributes: attributes)
        }
        self = .init(label: nil, layouts: layouts)
    }
}

public extension VertexDescriptor {
    /// Convenience method for creating packed descriptors with common attribute types/sizes...
    static func packed(label: String? = nil, semantics: [Attribute.Semantic]) -> VertexDescriptor {
        let attributes: [Attribute] = semantics.map { semantic in
            let format: MTLVertexFormat = switch semantic {
            case .position, .normal:
                .float3
            case .textureCoordinate:
                .float2
            }
            return .init(semantic: semantic, format: format, offset: 0)
        }
        let layout = Layout(bufferIndex: 0, stride: 0, stepFunction: .perVertex, stepRate: 1, attributes: attributes)
        var descriptor = VertexDescriptor(label: label, layouts: [layout])
        descriptor.setPackedOffsets()
        descriptor.setPackedStrides()
        return descriptor
    }
}

// MARK: Move.

extension MTLVertexStepFunction {
    var stringValue: String {
        switch self {
        case .constant: return "constant"
        case .perVertex: return "perVertex"
        case .perInstance: return "perInstance"
        case .perPatch: return "perPatch"
        case .perPatchControlPoint: return "perPatchControlPoint"
        @unknown default:
            fatalError("Unhandled case: \(self)")
        }
    }
}

extension MTLVertexFormat {
    var stringValue: String {
        switch self {
        case .invalid: return "invalid"
        case .uchar2: return "uchar2"
        case .uchar3: return "uchar3"
        case .uchar4: return "uchar4"
        case .char2: return "char2"
        case .char3: return "char3"
        case .char4: return "char4"
        case .uchar2Normalized: return "uchar2Normalized"
        case .uchar3Normalized: return "uchar3Normalized"
        case .uchar4Normalized: return "uchar4Normalized"
        case .char2Normalized: return "char2Normalized"
        case .char3Normalized: return "char3Normalized"
        case .char4Normalized: return "char4Normalized"
        case .ushort2: return "ushort2"
        case .ushort3: return "ushort3"
        case .ushort4: return "ushort4"
        case .short2: return "short2"
        case .short3: return "short3"
        case .short4: return "short4"
        case .ushort2Normalized: return "ushort2Normalized"
        case .ushort3Normalized: return "ushort3Normalized"
        case .ushort4Normalized: return "ushort4Normalized"
        case .short2Normalized: return "short2Normalized"
        case .short3Normalized: return "short3Normalized"
        case .short4Normalized: return "short4Normalized"
        case .half2: return "half2"
        case .half3: return "half3"
        case .half4: return "half4"
        case .float: return "float"
        case .float2: return "float2"
        case .float3: return "float3"
        case .float4: return "float4"
        case .int: return "int"
        case .int2: return "int2"
        case .int3: return "int3"
        case .int4: return "int4"
        case .uint: return "uint"
        case .uint2: return "uint2"
        case .uint3: return "uint3"
        case .uint4: return "uint4"
        case .int1010102Normalized: return "int1010102Normalized"
        case .uint1010102Normalized: return "uint1010102Normalized"
        case .uchar4Normalized_bgra: return "uchar4Normalized_bgra"
        case .uchar: return "uchar"
        case .char: return "char"
        case .ucharNormalized: return "ucharNormalized"
        case .charNormalized: return "charNormalized"
        case .ushort: return "ushort"
        case .short: return "short"
        case .ushortNormalized: return "ushortNormalized"
        case .shortNormalized: return "shortNormalized"
        case .half: return "half"
        case .floatRG11B10: return "floatRG11B10"
        case .floatRGB9E5: return "floatRGB9E5"
        @unknown default:
            fatalError("Unhandled MTLVertexFormat: \(self)")
        }
    }
}
