import Metal
import ModelIO

extension MDLMeshBufferType: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .index:
            "index"
        case .vertex:
            "vertex"
        case .custom:
            "custom"
        @unknown default:
            fatalError()
        }
    }
}

extension MDLGeometryType: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .lines:
            return "lines"
        case .points:
            return "points"
        case .triangles:
            return "triangles"
        case .triangleStrips:
            return "triangleStrips"
        case .quads:
            return "quads"
        case .variableTopology:
            return "variableTopology"
        @unknown default:
            fatalError()
        }
    }
}

extension MTLPixelFormat: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        // swiftlint:disable switch_case_on_newline
        case .invalid: return "invalid"
        case .a8Unorm: return "a8Unorm"
        case .r8Unorm: return "r8Unorm"
        case .r8Unorm_srgb: return "r8Unorm_srgb"
        case .r8Snorm: return "r8Snorm"
        case .r8Uint: return "r8Uint"
        case .r8Sint: return "r8Sint"
        case .r16Unorm: return "r16Unorm"
        case .r16Snorm: return "r16Snorm"
        case .r16Uint: return "r16Uint"
        case .r16Sint: return "r16Sint"
        case .r16Float: return "r16Float"
        case .rg8Unorm: return "rg8Unorm"
        case .rg8Unorm_srgb: return "rg8Unorm_srgb"
        case .rg8Snorm: return "rg8Snorm"
        case .rg8Uint: return "rg8Uint"
        case .rg8Sint: return "rg8Sint"
        case .b5g6r5Unorm: return "b5g6r5Unorm"
        case .a1bgr5Unorm: return "a1bgr5Unorm"
        case .abgr4Unorm: return "abgr4Unorm"
        case .bgr5A1Unorm: return "bgr5A1Unorm"
        case .r32Uint: return "r32Uint"
        case .r32Sint: return "r32Sint"
        case .r32Float: return "r32Float"
        case .rg16Unorm: return "rg16Unorm"
        case .rg16Snorm: return "rg16Snorm"
        case .rg16Uint: return "rg16Uint"
        case .rg16Sint: return "rg16Sint"
        case .rg16Float: return "rg16Float"
        case .rgba8Unorm: return "rgba8Unorm"
        case .rgba8Unorm_srgb: return "rgba8Unorm_srgb"
        case .rgba8Snorm: return "rgba8Snorm"
        case .rgba8Uint: return "rgba8Uint"
        case .rgba8Sint: return "rgba8Sint"
        case .bgra8Unorm: return "bgra8Unorm"
        case .bgra8Unorm_srgb: return "bgra8Unorm_srgb"
        case .rgb10a2Unorm: return "rgb10a2Unorm"
        case .rgb10a2Uint: return "rgb10a2Uint"
        case .rg11b10Float: return "rg11b10Float"
        case .rgb9e5Float: return "rgb9e5Float"
        case .bgr10a2Unorm: return "bgr10a2Unorm"
        case .bgr10_xr: return "bgr10_xr"
        case .bgr10_xr_srgb: return "bgr10_xr_srgb"
        case .rg32Uint: return "rg32Uint"
        case .rg32Sint: return "rg32Sint"
        case .rg32Float: return "rg32Float"
        case .rgba16Unorm: return "rgba16Unorm"
        case .rgba16Snorm: return "rgba16Snorm"
        case .rgba16Uint: return "rgba16Uint"
        case .rgba16Sint: return "rgba16Sint"
        case .rgba16Float: return "rgba16Float"
        case .bgra10_xr: return "bgra10_xr"
        case .bgra10_xr_srgb: return "bgra10_xr_srgb"
        case .rgba32Uint: return "rgba32Uint"
        case .rgba32Sint: return "rgba32Sint"
        case .rgba32Float: return "rgba32Float"
        case .bc1_rgba: return "bc1_rgba"
        case .bc1_rgba_srgb: return "bc1_rgba_srgb"
        case .bc2_rgba: return "bc2_rgba"
        case .bc2_rgba_srgb: return "bc2_rgba_srgb"
        case .bc3_rgba: return "bc3_rgba"
        case .bc3_rgba_srgb: return "bc3_rgba_srgb"
        case .bc4_rUnorm: return "bc4_rUnorm"
        case .bc4_rSnorm: return "bc4_rSnorm"
        case .bc5_rgUnorm: return "bc5_rgUnorm"
        case .bc5_rgSnorm: return "bc5_rgSnorm"
        case .bc6H_rgbFloat: return "bc6H_rgbFloat"
        case .bc6H_rgbuFloat: return "bc6H_rgbuFloat"
        case .bc7_rgbaUnorm: return "bc7_rgbaUnorm"
        case .bc7_rgbaUnorm_srgb: return "bc7_rgbaUnorm_srgb"
        case .pvrtc_rgb_2bpp: return "pvrtc_rgb_2bpp"
        case .pvrtc_rgb_2bpp_srgb: return "pvrtc_rgb_2bpp_srgb"
        case .pvrtc_rgb_4bpp: return "pvrtc_rgb_4bpp"
        case .pvrtc_rgb_4bpp_srgb: return "pvrtc_rgb_4bpp_srgb"
        case .pvrtc_rgba_2bpp: return "pvrtc_rgba_2bpp"
        case .pvrtc_rgba_2bpp_srgb: return "pvrtc_rgba_2bpp_srgb"
        case .pvrtc_rgba_4bpp: return "pvrtc_rgba_4bpp"
        case .pvrtc_rgba_4bpp_srgb: return "pvrtc_rgba_4bpp_srgb"
        case .eac_r11Unorm: return "eac_r11Unorm"
        case .eac_r11Snorm: return "eac_r11Snorm"
        case .eac_rg11Unorm: return "eac_rg11Unorm"
        case .eac_rg11Snorm: return "eac_rg11Snorm"
        case .eac_rgba8: return "eac_rgba8"
        case .eac_rgba8_srgb: return "eac_rgba8_srgb"
        case .etc2_rgb8: return "etc2_rgb8"
        case .etc2_rgb8_srgb: return "etc2_rgb8_srgb"
        case .etc2_rgb8a1: return "etc2_rgb8a1"
        case .etc2_rgb8a1_srgb: return "etc2_rgb8a1_srgb"
        case .astc_4x4_srgb: return "astc_4x4_srgb"
        case .astc_5x4_srgb: return "astc_5x4_srgb"
        case .astc_5x5_srgb: return "astc_5x5_srgb"
        case .astc_6x5_srgb: return "astc_6x5_srgb"
        case .astc_6x6_srgb: return "astc_6x6_srgb"
        case .astc_8x5_srgb: return "astc_8x5_srgb"
        case .astc_8x6_srgb: return "astc_8x6_srgb"
        case .astc_8x8_srgb: return "astc_8x8_srgb"
        case .astc_10x5_srgb: return "astc_10x5_srgb"
        case .astc_10x6_srgb: return "astc_10x6_srgb"
        case .astc_10x8_srgb: return "astc_10x8_srgb"
        case .astc_10x10_srgb: return "astc_10x10_srgb"
        case .astc_12x10_srgb: return "astc_12x10_srgb"
        case .astc_12x12_srgb: return "astc_12x12_srgb"
        case .astc_4x4_ldr: return "astc_4x4_ldr"
        case .astc_5x4_ldr: return "astc_5x4_ldr"
        case .astc_5x5_ldr: return "astc_5x5_ldr"
        case .astc_6x5_ldr: return "astc_6x5_ldr"
        case .astc_6x6_ldr: return "astc_6x6_ldr"
        case .astc_8x5_ldr: return "astc_8x5_ldr"
        case .astc_8x6_ldr: return "astc_8x6_ldr"
        case .astc_8x8_ldr: return "astc_8x8_ldr"
        case .astc_10x5_ldr: return "astc_10x5_ldr"
        case .astc_10x6_ldr: return "astc_10x6_ldr"
        case .astc_10x8_ldr: return "astc_10x8_ldr"
        case .astc_10x10_ldr: return "astc_10x10_ldr"
        case .astc_12x10_ldr: return "astc_12x10_ldr"
        case .astc_12x12_ldr: return "astc_12x12_ldr"
        case .astc_4x4_hdr: return "astc_4x4_hdr"
        case .astc_5x4_hdr: return "astc_5x4_hdr"
        case .astc_5x5_hdr: return "astc_5x5_hdr"
        case .astc_6x5_hdr: return "astc_6x5_hdr"
        case .astc_6x6_hdr: return "astc_6x6_hdr"
        case .astc_8x5_hdr: return "astc_8x5_hdr"
        case .astc_8x6_hdr: return "astc_8x6_hdr"
        case .astc_8x8_hdr: return "astc_8x8_hdr"
        case .astc_10x5_hdr: return "astc_10x5_hdr"
        case .astc_10x6_hdr: return "astc_10x6_hdr"
        case .astc_10x8_hdr: return "astc_10x8_hdr"
        case .astc_10x10_hdr: return "astc_10x10_hdr"
        case .astc_12x10_hdr: return "astc_12x10_hdr"
        case .astc_12x12_hdr: return "astc_12x12_hdr"
        case .gbgr422: return "gbgr422"
        case .bgrg422: return "bgrg422"
        case .depth16Unorm: return "depth16Unorm"
        case .depth32Float: return "depth32Float"
        case .stencil8: return "stencil8"
        case .depth24Unorm_stencil8: return "depth24Unorm_stencil8"
        case .depth32Float_stencil8: return "depth32Float_stencil8"
        case .x32_stencil8: return "x32_stencil8"
        case .x24_stencil8: return "x24_stencil8"
        // swiftlint:enable switch_case_on_newline
        @unknown default:
            fatalError("Unknown case \(self)")
        }
    }
}

extension MTLVertexFormat: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        // swiftlint:disable switch_case_on_newline
        case .invalid: "invalid"
        case .uchar2: "uchar2"
        case .uchar3: "uchar3"
        case .uchar4: "uchar4"
        case .char2: "char2"
        case .char3: "char3"
        case .char4: "char4"
        case .uchar2Normalized: "uchar2Normalized"
        case .uchar3Normalized: "uchar3Normalized"
        case .uchar4Normalized: "uchar4Normalized"
        case .char2Normalized: "char2Normalized"
        case .char3Normalized: "char3Normalized"
        case .char4Normalized: "char4Normalized"
        case .ushort2: "ushort2"
        case .ushort3: "ushort3"
        case .ushort4: "ushort4"
        case .short2: "short2"
        case .short3: "short3"
        case .short4: "short4"
        case .ushort2Normalized: "ushort2Normalized"
        case .ushort3Normalized: "ushort3Normalized"
        case .ushort4Normalized: "ushort4Normalized"
        case .short2Normalized: "short2Normalized"
        case .short3Normalized: "short3Normalized"
        case .short4Normalized: "short4Normalized"
        case .half2: "half2"
        case .half3: "half3"
        case .half4: "half4"
        case .float: "float"
        case .float2: "float2"
        case .float3: "float3"
        case .float4: "float4"
        case .int: "int"
        case .int2: "int2"
        case .int3: "int3"
        case .int4: "int4"
        case .uint: "uint"
        case .uint2: "uint2"
        case .uint3: "uint3"
        case .uint4: "uint4"
        case .int1010102Normalized: "int1010102Normalized"
        case .uint1010102Normalized: "uint1010102Normalized"
        case .uchar4Normalized_bgra: "uchar4Normalized_bgra"
        case .uchar: "uchar"
        case .char: "char"
        case .ucharNormalized: "ucharNormalized"
        case .charNormalized: "charNormalized"
        case .ushort: "ushort"
        case .short: "short"
        case .ushortNormalized: "ushortNormalized"
        case .shortNormalized: "shortNormalized"
        case .half: "half"
        default:
            fatalError("Unknown case \(self)")
        }
    }
}

extension MTLArgumentBuffersTier: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .tier1:
            return "tier1"
        case .tier2:
            return "tier2"
        @unknown default:
            fatalError("Unknown case \(self)")
        }
    }
}

extension MTLReadWriteTextureTier: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .tierNone:
            return "none"
        case .tier1:
            return "tier1"
        case .tier2:
            return "tier2"
        @unknown default:
            fatalError("Unknown case \(self)")
        }
    }
}

extension MTLGPUFamily: @retroactive CaseIterable, @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .apple1: return "apple1"
        case .apple2: return "apple2"
        case .apple3: return "apple3"
        case .apple4: return "apple4"
        case .apple5: return "apple5"
        case .apple6: return "apple6"
        case .apple7: return "apple7"
        case .mac1: return "mac1"
        case .mac2: return "mac2"
        case .common1: return "common1"
        case .common2: return "common2"
        case .common3: return "common3"
        case .macCatalyst1: return "macCatalyst1"
        case .macCatalyst2: return "macCatalyst2"
        case .apple8: return "apple8"
        case .metal3: return "metal3"
        case .apple9: return "apple9"
        @unknown default:
            fatalError("Unknown MTLGPUFamily")
        }
    }

    public static var allCases: [MTLGPUFamily] {
        var result: [MTLGPUFamily] = [
            .apple1,
            .apple2,
            .apple3,
            .apple4,
            .apple5,
            .apple6,
            .apple7,
            .apple8,
            .mac2,
            .common1,
            .common2,
            .common3,
            .metal3,
        ]
        #if os(iOS)
            result += [.apple9]
        #endif
        return result
    }
}

extension MTLWinding: @retroactive CaseIterable, @retroactive CustomStringConvertible {
    public static let allCases: [MTLWinding] = [.clockwise, .counterClockwise]

    public var description: String {
        switch self {
        case .clockwise:
            return "clockwise"
        case .counterClockwise:
            return "counterClockwise"
        @unknown default:
            fatalError("Unexpected case")
        }
    }
}

extension MTLCullMode: @retroactive CaseIterable, @retroactive CustomStringConvertible {
    public static let allCases: [MTLCullMode] = [.back, .front, .none]

    public var description: String {
        switch self {
        case .back:
            return "back"
        case .front:
            return "front"
        case .none:
            return "none"
        @unknown default:
            fatalError("Unexpected case")
        }
    }
}

extension MTLTriangleFillMode: @retroactive CaseIterable {
    public static let allCases: [MTLTriangleFillMode] = [.fill, .lines]
}

extension MTLTriangleFillMode: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .fill: "fill"
        case .lines: "lines"
        default:
            fatalError("Unexpected case")
        }
    }
}

extension MTLCompareFunction: @retroactive CaseIterable, @retroactive CustomStringConvertible {
    public static let allCases: [MTLCompareFunction] = [
        .never,
        .less,
        .equal,
        .lessEqual,
        .greater,
        .notEqual,
        .greaterEqual,
        .always,
    ]

    public var description: String {
        switch self {
        case .never: return "never"
        case .less: return "less"
        case .equal: return "equal"
        case .lessEqual: return "lessEqual"
        case .greater: return "greater"
        case .notEqual: return "notEqual"
        case .greaterEqual: return "greaterEqual"
        case .always: return "always"
        @unknown default:
            fatalError("Unexpected case")
        }
    }
}

extension MTLSize: @retroactive ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Int...) {
        assert(elements.count == 3)
        self = MTLSize(width: elements[0], height: elements[1], depth: elements[2])
    }
}

extension MTLResourceUsage: @retroactive Hashable {
}

extension MTLRenderStages: @retroactive Hashable {
}

extension MTLSize: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let width = try container.decode(Int.self)
        let height = try container.decode(Int.self)
        let depth = try container.decode(Int.self)
        self = MTLSize(width: width, height: height, depth: depth)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(width)
        try container.encode(height)
        try container.encode(depth)
    }
}

extension MTLResourceUsage: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let strings = try container.decode([String].self)
        let mapping = [
            "read": MTLResourceUsage.read,
            "write": MTLResourceUsage.write,
        ]
        assert(!strings.contains("sample"))
        let usages: [MTLResourceUsage] = strings.map { mapping[$0]! }
        self = MTLResourceUsage(usages)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let mapping = [
            (MTLResourceUsage.read, "read"),
            (MTLResourceUsage.write, "write"),
        ]
        let strings = mapping.compactMap { contains($0.0) ? $0.1 : nil }
        try container.encode(strings)
    }
}

extension MTLTextureType: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .type1D:
            return "1D"
        case .type1DArray:
            return "1DArray"
        case .type2D:
            return "2D"
        case .type2DArray:
            return "2DArray"
        case .type2DMultisample:
            return "2DMultisample"
        case .typeCube:
            return "Cube"
        case .typeCubeArray:
            return "CubeArray"
        case .type3D:
            return "3D"
        case .type2DMultisampleArray:
            return "2DMultisample"
        case .typeTextureBuffer:
            return "TextureBuffer"
        @unknown default:
            fatalError("Unknown texture type: \(self)")
        }
    }
}

extension MTLTextureUsage: @retroactive CustomStringConvertible {
    public var description: String {
        var atoms: [String] = []
        if self == .unknown {
            return "unknown"
        }
        else if contains(.shaderRead) {
            atoms.append("shaderRead")
        }
        else if contains(.shaderWrite) {
            atoms.append("shaderWrite")
        }
        else if contains(.renderTarget) {
            atoms.append("renderTarget")
        }
        else if contains(.pixelFormatView) {
            atoms.append("pixelFormatView")
        }
        return atoms.joined(separator: ", ")
    }
}

extension MTLTextureCompressionType: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .lossless:
            return "lossless"
        case .lossy:
            return "lossy"
        @unknown default:
            fatalError("Unknown texture compression type: \(self)")
        }
    }
}

extension MTLPixelFormat: @retroactive CaseIterable {
    public static var allCases: [MTLPixelFormat] {
        let baseCases: [MTLPixelFormat] = [
            .invalid,
            .a8Unorm,
            .r8Unorm,
            .r8Unorm_srgb,
            .r8Snorm,
            .r8Uint,
            .r8Sint,
            .r16Unorm,
            .r16Snorm,
            .r16Uint,
            .r16Sint,
            .r16Float,
            .rg8Unorm,
            .rg8Unorm_srgb,
            .rg8Snorm,
            .rg8Uint,
            .rg8Sint,
            .b5g6r5Unorm,
            .a1bgr5Unorm,
            .abgr4Unorm,
            .bgr5A1Unorm,
            .r32Uint,
            .r32Sint,
            .r32Float,
            .rg16Unorm,
            .rg16Snorm,
            .rg16Uint,
            .rg16Sint,
            .rg16Float,
            .rgba8Unorm,
            .rgba8Unorm_srgb,
            .rgba8Snorm,
            .rgba8Uint,
            .rgba8Sint,
            .bgra8Unorm,
            .bgra8Unorm_srgb,
            .rgb10a2Unorm,
            .rgb10a2Uint,
            .rg11b10Float,
            .rgb9e5Float,
            .bgr10a2Unorm,
            .bgr10_xr,
            .bgr10_xr_srgb,
            .rg32Uint,
            .rg32Sint,
            .rg32Float,
            .rgba16Unorm,
            .rgba16Snorm,
            .rgba16Uint,
            .rgba16Sint,
            .rgba16Float,
            .bgra10_xr,
            .bgra10_xr_srgb,
            .rgba32Uint,
            .rgba32Sint,
            .rgba32Float,
            .bc1_rgba,
            .bc1_rgba_srgb,
            .bc2_rgba,
            .bc2_rgba_srgb,
            .bc3_rgba,
            .bc3_rgba_srgb,
            .bc4_rUnorm,
            .bc4_rSnorm,
            .bc5_rgUnorm,
            .bc5_rgSnorm,
            .bc6H_rgbFloat,
            .bc6H_rgbuFloat,
            .bc7_rgbaUnorm,
            .bc7_rgbaUnorm_srgb,
//            .pvrtc_rgb_2bpp,
//            .pvrtc_rgb_2bpp_srgb,
//            .pvrtc_rgb_4bpp,
//            .pvrtc_rgb_4bpp_srgb,
//            .pvrtc_rgba_2bpp,
//            .pvrtc_rgba_2bpp_srgb,
//            .pvrtc_rgba_4bpp,
//            .pvrtc_rgba_4bpp_srgb,
            .eac_r11Unorm,
            .eac_r11Snorm,
            .eac_rg11Unorm,
            .eac_rg11Snorm,
            .eac_rgba8,
            .eac_rgba8_srgb,
            .etc2_rgb8,
            .etc2_rgb8_srgb,
            .etc2_rgb8a1,
            .etc2_rgb8a1_srgb,
            .astc_4x4_srgb,
            .astc_5x4_srgb,
            .astc_5x5_srgb,
            .astc_6x5_srgb,
            .astc_6x6_srgb,
            .astc_8x5_srgb,
            .astc_8x6_srgb,
            .astc_8x8_srgb,
            .astc_10x5_srgb,
            .astc_10x6_srgb,
            .astc_10x8_srgb,
            .astc_10x10_srgb,
            .astc_12x10_srgb,
            .astc_12x12_srgb,
            .astc_4x4_ldr,
            .astc_5x4_ldr,
            .astc_5x5_ldr,
            .astc_6x5_ldr,
            .astc_6x6_ldr,
            .astc_8x5_ldr,
            .astc_8x6_ldr,
            .astc_8x8_ldr,
            .astc_10x5_ldr,
            .astc_10x6_ldr,
            .astc_10x8_ldr,
            .astc_10x10_ldr,
            .astc_12x10_ldr,
            .astc_12x12_ldr,
            .astc_4x4_hdr,
            .astc_5x4_hdr,
            .astc_5x5_hdr,
            .astc_6x5_hdr,
            .astc_6x6_hdr,
            .astc_8x5_hdr,
            .astc_8x6_hdr,
            .astc_8x8_hdr,
            .astc_10x5_hdr,
            .astc_10x6_hdr,
            .astc_10x8_hdr,
            .astc_10x10_hdr,
            .astc_12x10_hdr,
            .astc_12x12_hdr,
            .gbgr422,
            .bgrg422,
            .depth16Unorm,
            .depth32Float,
            .stencil8,
            .depth32Float_stencil8,
            .x32_stencil8,
        ]

        #if os(macOS)
            return baseCases + [
                .depth24Unorm_stencil8,
                .x24_stencil8,
            ]
        #else
            return baseCases
        #endif
    }
}

extension MTLStepFunction: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .perVertex:
            "perVertex"
        case .perInstance:
            "perInstance"
        default:
            fatalError("unimplemented")
        }
    }
}

extension MTLOrigin: @retroactive ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Int...) {
        self = .init(x: elements[0], y: elements[1], z: elements[2])
    }
}