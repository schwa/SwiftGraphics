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

public extension MTLBuffer {
    func data() -> Data {
        Data(bytes: contents(), count: length)
    }

    /// Update a MTLBuffer's contents using an inout type block
    func with<T, R>(type: T.Type, _ block: (inout T) -> R) -> R {
        let value = contents().bindMemory(to: T.self, capacity: 1)
        return block(&value.pointee)
    }

    func withEx<T, R>(type: T.Type, count: Int, _ block: (UnsafeMutableBufferPointer<T>) -> R) -> R {
        let pointer = contents().bindMemory(to: T.self, capacity: count)
        let buffer = UnsafeMutableBufferPointer(start: pointer, count: count)
        return block(buffer)
    }

    func contentsBuffer() -> UnsafeMutableRawBufferPointer {
        UnsafeMutableRawBufferPointer(start: contents(), count: length)
    }

    func contentsBuffer<T>(of type: T.Type) -> UnsafeMutableBufferPointer<T> {
        contentsBuffer().bindMemory(to: type)
    }
    func labelled(_ label: String) -> MTLBuffer {
        self.label = label
        return self
    }
}

public extension MTLCommandBuffer {
    func withRenderCommandEncoder<R>(descriptor: MTLRenderPassDescriptor, label: String? = nil, useDebugGroup: Bool = false, block: (MTLRenderCommandEncoder) throws -> R) throws -> R {
        guard let renderCommandEncoder = makeRenderCommandEncoder(descriptor: descriptor) else {
            throw BaseError.resourceCreationFailure
        }
        if let label {
            renderCommandEncoder.label = label
        }
        defer {
            renderCommandEncoder.endEncoding()
        }
        return try renderCommandEncoder.withDebugGroup("Encode \(label ?? "RenderCommandEncoder")", enabled: useDebugGroup) {
            try block(renderCommandEncoder)
        }
    }

    func withComputeCommandEncoder<R>(label: String? = nil, useDebugGroup: Bool = false, block: (MTLComputeCommandEncoder) throws -> R) rethrows -> R {
        guard let commandEncoder = makeComputeCommandEncoder() else {
            fatalError("Failed to make command encoder.")
        }
        if let label {
            commandEncoder.label = label
        }
        defer {
            commandEncoder.endEncoding()
        }
        return try commandEncoder.withDebugGroup("Encode \(label ?? "ComputeCommandEncoder")", enabled: useDebugGroup) {
            try block(commandEncoder)
        }
    }

    func withComputeCommandEncoder<R>(descriptor: MTLComputePassDescriptor, label: String? = nil, useDebugGroup: Bool = false, block: (MTLComputeCommandEncoder) throws -> R) rethrows -> R {
        guard let commandEncoder = makeComputeCommandEncoder(descriptor: descriptor) else {
            fatalError("Failed to make command encoder.")
        }
        if let label {
            commandEncoder.label = label
        }
        defer {
            commandEncoder.endEncoding()
        }
        return try commandEncoder.withDebugGroup("Encode \(label ?? "ComputeCommandEncoder")", enabled: useDebugGroup) {
            try block(commandEncoder)
        }
    }
}

public extension MTLCommandEncoder {
    func withDebugGroup<R>(_ string: String, enabled: Bool = true, _ closure: () throws -> R) rethrows -> R {
        if enabled {
            pushDebugGroup(string)
        }
        defer {
            if enabled {
                popDebugGroup()
            }
        }
        return try closure()
    }
}

public extension MTLCommandQueue {
    func withCommandBuffer<R>(descriptor: MTLCommandBufferDescriptor? = nil, waitAfterCommit wait: Bool, block: (MTLCommandBuffer) throws -> R) throws -> R {
        let descriptor = descriptor ?? .init()
        guard let commandBuffer = makeCommandBuffer(descriptor: descriptor) else {
            throw BaseError.resourceCreationFailure
        }
        defer {
            commandBuffer.commit()
            if wait {
                commandBuffer.waitUntilCompleted()
            }
        }
        return try block(commandBuffer)
    }

    func withCommandBuffer<R>(drawable: (any MTLDrawable)? = nil, block: (MTLCommandBuffer) throws -> R) throws -> R {
        guard let commandBuffer = makeCommandBuffer() else {
            throw BaseError.resourceCreationFailure
        }
        defer {
            if let drawable {
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

    @available(*, deprecated, message: "Deprecated")
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
