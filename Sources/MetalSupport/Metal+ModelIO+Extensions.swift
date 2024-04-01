import Metal
import ModelIO

public extension MTLVertexDescriptor {
    convenience init(_ vertexDescriptor: MDLVertexDescriptor) {
        self.init()
        for (index, attribute) in vertexDescriptor.attributes.enumerated() {
            // swiftlint:disable:next force_cast
            let attribute = attribute as! MDLVertexAttribute
            attributes[index].format = MTLVertexFormat(attribute.format)
            attributes[index].offset = attribute.offset
            attributes[index].bufferIndex = attribute.bufferIndex
        }
        // swiftlint:disable:next force_cast
        layouts[0].stride = (vertexDescriptor.layouts[0] as! MDLVertexBufferLayout).stride
    }
}

public extension MDLVertexDescriptor {
    convenience init(attributes: [MTLAttributeDescriptor]) {
        self.init()

        self.attributes.addObjects(from: attributes)
    }
}

public extension MTLVertexFormat {
    // swiftlint:disable cyclomatic_complexity
    init(_ format: MDLVertexFormat) {
        switch format {
        // swiftlint:disable switch_case_on_newline
        case .invalid: self = .invalid
        //        case .packedBit: self = .packedBit
        //        case .uCharBits: self = .uCharBits
        //        case .charBits: self = .charBits
        //        case .uCharNormalizedBits: self = .uCharNormalizedBits
        //        case .charNormalizedBits: self = .charNormalizedBits
        //        case .uShortBits: self = .uShortBits
        //        case .shortBits: self = .shortBits
        //        case .uShortNormalizedBits: self = .uShortNormalizedBits
        //        case .shortNormalizedBits: self = .shortNormalizedBits
        //        case .uIntBits: self = .uIntBits
        //        case .intBits: self = .intBits
        //        case .halfBits: self = .halfBits
        //        case .floatBits: self = .floatBits
        //        case .uChar: self = .uChar
        //        case .uChar2: self = .uChar2
        //        case .uChar3: self = .uChar3
        //        case .uChar4: self = .uChar4
        case .char: self = .char
        case .char2: self = .char2
        case .char3: self = .char3
        case .char4: self = .char4
        //        case .uCharNormalized: self = .uCharNormalized
        //        case .uChar2Normalized: self = .uChar2Normalized
        //        case .uChar3Normalized: self = .uChar3Normalized
        //        case .uChar4Normalized: self = .uChar4Normalized
        //        case .charNormalized: self = .charNormalized
        //        case .char2Normalized: self = .char2Normalized
        //        case .char3Normalized: self = .char3Normalized
        //        case .char4Normalized: self = .char4Normalized
        //        case .uShort: self = .uShort
        //        case .uShort2: self = .uShort2
        //        case .uShort3: self = .uShort3
        //        case .uShort4: self = .uShort4
        case .short: self = .short
        case .short2: self = .short2
        case .short3: self = .short3
        case .short4: self = .short4
        //        case .uShortNormalized: self = .uShortNormalized
        //        case .uShort2Normalized: self = .uShort2Normalized
        //        case .uShort3Normalized: self = .uShort3Normalized
        //        case .uShort4Normalized: self = .uShort4Normalized
        //        case .shortNormalized: self = .shortNormalized
        //        case .short2Normalized: self = .short2Normalized
        //        case .short3Normalized: self = .short3Normalized
        //        case .short4Normalized: self = .short4Normalized
        //        case .uInt: self = .uInt
        //        case .uInt2: self = .uInt2
        //        case .uInt3: self = .uInt3
        //        case .uInt4: self = .uInt4
        case .int: self = .int
        case .int2: self = .int2
        case .int3: self = .int3
        case .int4: self = .int4
        case .half: self = .half
        case .half2: self = .half2
        case .half3: self = .half3
        case .half4: self = .half4
        case .float: self = .float
        case .float2: self = .float2
        case .float3: self = .float3
        case .float4: self = .float4
        //        case .int1010102Normalized: self = .int1010102Normalized
        //        case .uInt1010102Normalized: self = .uInt1010102Normalized
        default:
            fatalError("Unknown type \(format.rawValue)")
        }
    }
}
