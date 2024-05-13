import CoreGraphics
import Metal
import ModelIO
import simd

// swiftlint:disable function_body_length
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length
// swiftlint:disable function_parameter_count

public extension MTLArgumentDescriptor {
    @available(iOS 17, macOS 14, *)
    convenience init(dataType: MTLDataType, index: Int, arrayLength: Int? = nil, access: MTLBindingAccess? = nil, textureType: MTLTextureType? = nil, constantBlockAlignment: Int? = nil) {
        self.init()
        self.dataType = dataType
        self.index = index
        if let arrayLength {
            self.arrayLength = arrayLength
        }
        if let access {
            self.access = access
        }
        if let textureType {
            self.textureType = textureType
        }
        if let constantBlockAlignment {
            self.arrayLength = constantBlockAlignment
        }
    }
}

public extension MTLAttributeDescriptor {
    convenience init(format: MTLAttributeFormat, offset: Int = 0, bufferIndex: Int) {
        self.init()
        self.format = format
        self.offset = offset
        self.bufferIndex = bufferIndex
    }
}

public extension MTLBuffer {
    func data() -> Data {
        Data(bytes: contents(), count: length)
    }

    /// Update a MTLBuffer's contents using an inout type block
    func with<T, R>(type: T.Type, _ block: (inout T) -> R) -> R {
        let value = contents().bindMemory(to: T.self, capacity: 1)
        let result = block(&value.pointee)
        return result
    }

    func withEx<T, R>(type: T.Type, count: Int, _ block: (UnsafeMutableBufferPointer<T>) -> R) -> R {
        let pointer = contents().bindMemory(to: T.self, capacity: count)
        let buffer = UnsafeMutableBufferPointer(start: pointer, count: count)
        let result = block(buffer)
        return result
    }
}

public extension MTLCommandBuffer {
    func withRenderCommandEncoder<R>(descriptor: MTLRenderPassDescriptor, block: (MTLRenderCommandEncoder) throws -> R) rethrows -> R {
        guard let renderCommandEncoder = makeRenderCommandEncoder(descriptor: descriptor) else {
            // TODO: Better to throw?
            fatalError("Failed to make render command encoder.")
        }
        defer {
            renderCommandEncoder.endEncoding()
        }
        return try block(renderCommandEncoder)
    }
}

public extension MTLCommandQueue {
    func withCommandBuffer<R>(waitAfterCommit wait: Bool, block: (MTLCommandBuffer) throws -> R) rethrows -> R {
        guard let commandBuffer = makeCommandBuffer() else {
            fatalError("Failed to make command buffer.")
        }
        defer {
            commandBuffer.commit()
            if wait {
                commandBuffer.waitUntilCompleted()
            }
        }
        return try block(commandBuffer)
    }

    func withCommandBuffer<R>(drawable: @autoclosure () -> (any MTLDrawable)?, block: (MTLCommandBuffer) throws -> R) rethrows -> R {
        guard let commandBuffer = makeCommandBuffer() else {
            fatalError("Failed to make command buffer.")
        }
        defer {
            if let drawable = drawable() {
                commandBuffer.present(drawable)
            }
            commandBuffer.commit()
        }
        return try block(commandBuffer)
    }
}

public extension MTLDepthStencilDescriptor {
    convenience init(depthCompareFunction: MTLCompareFunction, isDepthWriteEnabled: Bool) {
        self.init()
        self.depthCompareFunction = depthCompareFunction
        self.isDepthWriteEnabled = isDepthWriteEnabled
    }
}

public extension MTLDevice {
    func makeBuffer(bytesOf content: some Any, options: MTLResourceOptions) -> MTLBuffer? {
        withUnsafeBytes(of: content) { buffer in
            makeBuffer(bytes: buffer.baseAddress!, length: buffer.count, options: options)
        }
    }

    func makeBuffer(bytesOf content: [some Any], options: MTLResourceOptions) -> MTLBuffer? {
        content.withUnsafeBytes { buffer in
            makeBuffer(bytes: buffer.baseAddress!, length: buffer.count, options: options)
        }
    }

    var supportsNonuniformThreadGroupSizes: Bool {
        let families: [MTLGPUFamily] = [.apple4, .apple5, .apple6, .apple7]
        return families.contains { supportsFamily($0) }
    }
}

public extension MTLIndexType {
    var indexSize: Int {
        switch self {
        case .uint16:
            MemoryLayout<UInt16>.size
        case .uint32:
            MemoryLayout<UInt32>.size
        default:
            fatal(error: MetalSupportError.illegalValue)
        }
    }
}

public extension MTLOrigin {
    static var zero: MTLOrigin {
        MTLOrigin(x: 0, y: 0, z: 0)
    }

    init(_ origin: CGPoint) {
        self.init(x: Int(origin.x), y: Int(origin.y), z: 0)
    }
}

public extension MTLPixelFormat {
    var bits: Int? {
        switch self {
        /* Normal 8 bit formats */
        case .a8Unorm, .r8Unorm, .r8Unorm_srgb, .r8Snorm, .r8Uint, .r8Sint:
            8
        /* Normal 16 bit formats */
        case .r16Unorm, .r16Snorm, .r16Uint, .r16Sint, .r16Float, .rg8Unorm, .rg8Unorm_srgb, .rg8Snorm, .rg8Uint, .rg8Sint:
            16
        /* Packed 16 bit formats */
        case .b5g6r5Unorm, .a1bgr5Unorm, .abgr4Unorm, .bgr5A1Unorm:
            16
        /* Normal 32 bit formats */
        case .r32Uint, .r32Sint, .r32Float, .rg16Unorm, .rg16Snorm, .rg16Uint, .rg16Sint, .rg16Float, .rgba8Unorm, .rgba8Unorm_srgb, .rgba8Snorm, .rgba8Uint, .rgba8Sint, .bgra8Unorm, .bgra8Unorm_srgb:
            32
        /* Packed 32 bit formats */
        case .rgb10a2Unorm, .rgb10a2Uint, .rg11b10Float, .rgb9e5Float, .bgr10a2Unorm, .bgr10_xr, .bgr10_xr_srgb:
            32
        /* Normal 64 bit formats */
        case .rg32Uint, .rg32Sint, .rg32Float, .rgba16Unorm, .rgba16Snorm, .rgba16Uint, .rgba16Sint, .rgba16Float, .bgra10_xr, .bgra10_xr_srgb:
            64
        /* Normal 128 bit formats */
        case .rgba32Uint, .rgba32Sint, .rgba32Float:
            128
        /* Depth */
        case .depth16Unorm:
            16
        case .depth32Float:
            32
        /* Stencil */
        case .stencil8:
            8
        /* Depth Stencil */
        case .depth24Unorm_stencil8:
            32
        case .depth32Float_stencil8:
            40
        case .x32_stencil8:
            nil
        case .x24_stencil8:
            nil
        default:
            nil
        }
    }

    var size: Int? {
        bits.map { $0 / 8 }
    }
}

public extension MTLPrimitiveType {
    var vertexCount: Int? {
        switch self {
        case .triangle:
            3
        default:
            fatal(error: MetalSupportError.illegalValue)
        }
    }
}

public extension MTLRegion {
    init(_ rect: CGRect) {
        self = MTLRegion(origin: MTLOrigin(rect.origin), size: MTLSize(rect.size))
    }
}

public extension MTLSize {
    init(_ width: Int, _ height: Int, _ depth: Int) {
        self = MTLSize(width: width, height: height, depth: depth)
    }

    init(_ size: CGSize) {
        self.init(width: Int(size.width), height: Int(size.height), depth: 1)
    }
}

public extension MTLTexture {
    var size: MTLSize {
        MTLSize(width, height, depth)
    }

    var region: MTLRegion {
        MTLRegion(origin: .zero, size: size)
    }

    func clear(color: SIMD4<UInt8> = [0, 0, 0, 0]) {
        // TODO: This is crazy expensive. :-)
        assert(depth == 1)
        let buffer = Array(repeatElement(color, count: width * height * depth))
        assert(MemoryLayout<SIMD4<UInt8>>.stride == pixelFormat.size)
        buffer.withUnsafeBytes { pointer in
            replace(region: region, mipmapLevel: 0, withBytes: pointer.baseAddress!, bytesPerRow: width * MemoryLayout<SIMD4<UInt8>>.stride)
        }
    }
}

public extension MTLVertexDescriptor {
    // TODO: Only works for SIMPLE vertexes (one layout)
    @available(*, deprecated, message: "Too dangerous. Only works with single layouts.")
    convenience init(attributes: [MTLVertexAttribute]) {
        self.init()
        var offset = 0
        for (index, attribute) in attributes.enumerated() {
            let attributeDescriptor = MTLVertexAttributeDescriptor()
            attributeDescriptor.offset = offset
            attributeDescriptor.format = MTLVertexFormat(dataType: attribute.attributeType)!
            self.attributes[index] = attributeDescriptor
            offset += attributeDescriptor.format.size
        }
        layouts[0].stride = offset
    }

    convenience init(vertexDescriptor: MDLVertexDescriptor) {
        self.init()
        for (index, mdlAttribute) in vertexDescriptor.attributes.enumerated() {
            let mdlAttribute = mdlAttribute as! MDLVertexAttribute
            attributes[index].offset = mdlAttribute.offset
            attributes[index].bufferIndex = mdlAttribute.bufferIndex
            attributes[index].format = MTLVertexFormat(mdlAttribute.format)
        }
        for (index, mdlLayout) in vertexDescriptor.layouts.enumerated() {
            let mdlLayout = mdlLayout as! MDLVertexBufferLayout
            layouts[index].stride = mdlLayout.stride
        }
    }
}

public extension MTLVertexFormat {
    var size: Int {
        switch self {
        case .uchar, .ucharNormalized:
            return MemoryLayout<UInt8>.size
        case .uchar2, .uchar2Normalized:
            return 2 * MemoryLayout<UInt8>.size
        case .uchar3, .uchar3Normalized:
            return 3 * MemoryLayout<UInt8>.size
        case .uchar4, .uchar4Normalized:
            return 4 * MemoryLayout<UInt8>.size
        case .char, .charNormalized:
            return MemoryLayout<Int8>.size
        case .char2, .char2Normalized:
            return 2 * MemoryLayout<Int8>.size
        case .char3, .char3Normalized:
            return 3 * MemoryLayout<Int8>.size
        case .char4, .char4Normalized:
            return 4 * MemoryLayout<Int8>.size
        case .ushort, .ushortNormalized:
            return MemoryLayout<UInt16>.size
        case .ushort2, .ushort2Normalized:
            return 2 * MemoryLayout<UInt16>.size
        case .ushort3, .ushort3Normalized:
            return 3 * MemoryLayout<UInt16>.size
        case .ushort4, .ushort4Normalized:
            return 4 * MemoryLayout<UInt16>.size
        case .short, .shortNormalized:
            return MemoryLayout<Int16>.size
        case .short2, .short2Normalized:
            return 2 * MemoryLayout<Int16>.size
        case .short3, .short3Normalized:
            return 3 * MemoryLayout<Int16>.size
        case .short4, .short4Normalized:
            return 4 * MemoryLayout<Int16>.size
        case .half:
            #if arch(arm64)
                return MemoryLayout<Float16>.size
            #else
                return MemoryLayout<Int16>.size
            #endif
        case .half2:
            #if arch(arm64)
                return 2 * MemoryLayout<Float16>.size
            #else
                return 2 * MemoryLayout<Int16>.size
            #endif
        case .half3:
            #if arch(arm64)
                return 3 * MemoryLayout<Float16>.size
            #else
                return 3 * MemoryLayout<Int16>.size
            #endif
        case .half4:
            #if arch(arm64)
                return MemoryLayout<Float16>.size
            #else
                return MemoryLayout<Int16>.size
            #endif
        case .float:
            return MemoryLayout<Float>.size
        case .float2:
            return 2 * MemoryLayout<Float>.size
        case .float3:
            return 3 * MemoryLayout<Float>.size
        case .float4:
            return 4 * MemoryLayout<Float>.size
        case .int:
            return MemoryLayout<Int32>.size
        case .int2:
            return 2 * MemoryLayout<Int32>.size
        case .int3:
            return 3 * MemoryLayout<Int32>.size
        case .int4:
            return 4 * MemoryLayout<UInt32>.size
        case .uint:
            return MemoryLayout<UInt32>.size
        case .uint2:
            return 2 * MemoryLayout<UInt32>.size
        case .uint3:
            return 3 * MemoryLayout<UInt32>.size
        case .uint4:
            return 4 * MemoryLayout<UInt32>.size
        case .int1010102Normalized, .uint1010102Normalized:
            return MemoryLayout<UInt32>.size
        case .uchar4Normalized_bgra:
            return 4 * MemoryLayout<UInt8>.size
        default:
            fatalError("Unknown MTLVertexFormat \(self)")
        }
    }

    init?(dataType: MTLDataType) {
        switch dataType {
        case .float2:
            self = .float2
        case .float3:
            self = .float3
        case .float4:
            self = .float4
        case .half:
            self = .half
        case .half2:
            self = .half2
        case .half3:
            self = .half3
        case .half4:
            self = .half4
        case .int:
            self = .int
        case .int2:
            self = .int2
        case .int3:
            self = .int3
        case .int4:
            self = .int4
        case .uint:
            self = .uint
        case .uint2:
            self = .uint2
        case .uint3:
            self = .uint3
        case .uint4:
            self = .uint4
        case .short:
            self = .short
        case .short2:
            self = .short2
        case .short3:
            self = .short3
        case .short4:
            self = .short4
        case .ushort:
            self = .ushort
        case .ushort2:
            self = .ushort2
        case .ushort3:
            self = .ushort3
        case .ushort4:
            self = .ushort4
        case .char:
            self = .char
        case .char2:
            self = .char2
        case .char3:
            self = .char3
        case .char4:
            self = .char4
        case .uchar:
            self = .uchar
        case .uchar2:
            self = .uchar
        case .uchar3:
            self = .uchar3
        case .uchar4:
            self = .uchar4
        default:
            fatalError("Unsupported or unknown MTLDataType.")
        }
    }
}

public extension MTLTextureDescriptor {
    var bytesPerRow: Int? {
        pixelFormat.size.map { $0 * width }
    }
}
