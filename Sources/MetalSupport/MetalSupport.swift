// swiftlint:disable file_length

import BaseSupport
import CoreGraphics
import CoreGraphicsSupport
import Foundation
import Metal
import MetalKit
import MetalPerformanceShaders
import ModelIO
import os
import simd

public extension MTKMesh {
    func labelBuffers(_ label: String) {
        for (index, buffer) in vertexBuffers.enumerated() {
            buffer.buffer.label = "\(label)-vertexBuffer#\(index)"
        }
        for (index, submesh) in submeshes.enumerated() {
            submesh.indexBuffer.buffer.label = "\(label)-indexBuffer#\(index)"
        }
    }
}

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

public extension MTLDepthStencilDescriptor {
    convenience init(depthCompareFunction: MTLCompareFunction, isDepthWriteEnabled: Bool) {
        self.init()
        self.depthCompareFunction = depthCompareFunction
        self.isDepthWriteEnabled = isDepthWriteEnabled
    }
}

public extension MTLDevice {
    func capture <R>(enabled: Bool = true, _ block: () throws -> R) throws -> R {
        guard enabled else {
            return try block()
        }
        let captureManager = MTLCaptureManager.shared()
        let captureScope = captureManager.makeCaptureScope(device: self)
        let captureDescriptor = MTLCaptureDescriptor()
        captureDescriptor.captureObject = captureScope
        try captureManager.startCapture(with: captureDescriptor)
        captureScope.begin()
        defer {
            captureScope.end()
        }
        return try block()
    }

    var supportsNonuniformThreadGroupSizes: Bool {
        let families: [MTLGPUFamily] = [.apple4, .apple5, .apple6, .apple7]
        return families.contains { supportsFamily($0) }
    }

    // TODO: Deprecate?
    // @available(*, deprecated, message: "Deprecated")
    func makeDebugLibrary(bundle: Bundle) throws -> MTLLibrary {
        if let url = bundle.url(forResource: "debug", withExtension: "metallib") {
            return try makeLibrary(URL: url)
        }
        else {
            logger?.warning("Failed to load debug metal library, falling back to bundle's default library.")
            return try makeDefaultLibrary(bundle: bundle)
        }
    }

    func makeComputePipelineState(function: MTLFunction, options: MTLPipelineOption) throws -> (MTLComputePipelineState, MTLComputePipelineReflection?) {
        var reflection: MTLComputePipelineReflection?
        let pipelineState = try makeComputePipelineState(function: function, options: options, reflection: &reflection)
        return (pipelineState, reflection)
    }
}

public extension MTLFunctionConstantValues {
    convenience init(dictionary: [Int: Any]) {
        self.init()

        for (index, value) in dictionary {
            withUnsafeBytes(of: value) { buffer in
                let baseAddress = buffer.baseAddress.forceUnwrap("Could not get base Address")
                setConstantValue(baseAddress, type: .bool, index: index)
            }
        }
    }

    func setConstantValue(_ value: Bool, index: Int) {
        withUnsafeBytes(of: value) { buffer in
            let baseAddress = buffer.baseAddress.forceUnwrap("Could not get base Address")
            setConstantValue(baseAddress, type: .bool, index: index)
        }
    }
}

public extension MTLVertexDescriptor {
    convenience init(vertexDescriptor: MDLVertexDescriptor) {
        self.init()
        for (index, mdlAttribute) in vertexDescriptor.attributes.enumerated() {
            // swiftlint:disable:next force_cast
            let mdlAttribute = mdlAttribute as! MDLVertexAttribute
            attributes[index].offset = mdlAttribute.offset
            attributes[index].bufferIndex = mdlAttribute.bufferIndex
            attributes[index].format = MTLVertexFormat(mdlAttribute.format)
        }
        for (index, mdlLayout) in vertexDescriptor.layouts.enumerated() {
            // swiftlint:disable:next force_cast
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

    // swiftlint:disable:next cyclomatic_complexity
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
