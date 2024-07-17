import BaseSupport
import CoreGraphicsSupport
import Foundation
import Metal
import MetalSupport
import simd
import SIMDSupport

// swiftlint:disable force_unwrapping

public struct PackedHalf3: Hashable {
    public var x: Float16
    public var y: Float16
    public var z: Float16
}

public struct PackedHalf4: Hashable {
    public var x: Float16
    public var y: Float16
    public var z: Float16
    public var w: Float16
}

func max(lhs: PackedFloat3, rhs: PackedFloat3) -> PackedFloat3 {
    [max(lhs[0], rhs[0]), max(lhs[1], rhs[1]), max(lhs[2], rhs[2])]
}

func min(lhs: PackedFloat3, rhs: PackedFloat3) -> PackedFloat3 {
    [min(lhs[0], rhs[0]), min(lhs[1], rhs[1]), min(lhs[2], rhs[2])]
}

extension Collection where Element == PackedFloat3 {
    var bounds: (min: PackedFloat3, max: PackedFloat3) {
        (
            // swiftlint:disable:next reduce_into
            reduce([Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude], GaussianSplatSupport.min),
            // swiftlint:disable:next reduce_into
            reduce([-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude], GaussianSplatSupport.max)
        )
    }
}

public extension SIMD3 where Scalar == Float {
    init(_ other: PackedHalf3) {
        self = SIMD3(Scalar(other.x), Scalar(other.y), Scalar(other.z))
    }
}

extension PackedHalf3 {
    init(_ other: SIMD3<Float>) {
        self = PackedHalf3(x: Float16(other.x), y: Float16(other.y), z: Float16(other.z))
    }
}

extension PackedHalf4 {
    init(_ other: SIMD4<Float>) {
        self = PackedHalf4(x: Float16(other.x), y: Float16(other.y), z: Float16(other.z), w: Float16(other.w))
    }
}


public extension Bundle {
    static let gaussianSplatShaders: Bundle = {
        if let shadersBundleURL = Bundle.main.url(forResource: "SwiftGraphics_GaussianSplatShaders", withExtension: "bundle"), let bundle = Bundle(url: shadersBundleURL) {
            return bundle
        }
        // Fail.
        fatalError("Could not find shaders bundle")
    }()
}

extension simd_quatf {
    var vectorRealFirst: simd_float4 {
        [vector.w, vector.x, vector.y, vector.z]
    }
}

public extension MTLDevice {
    func makeTypedBuffer<T>(data: Data, options: MTLResourceOptions = []) throws -> TypedMTLBuffer<T> {
        if !data.count.isMultiple(of: MemoryLayout<T>.size) {
            throw BaseError.illegalValue
        }
        return try data.withUnsafeBytes { buffer in
            guard let buffer = makeBuffer(bytes: buffer.baseAddress!, length: buffer.count, options: options) else {
                throw BaseError.resourceCreationFailure
            }
            return TypedMTLBuffer(mtlBuffer: buffer)
        }
    }

    func makeTypedBuffer<T>(data: [T], options: MTLResourceOptions = []) throws -> TypedMTLBuffer<T> {
        try data.withUnsafeBytes { buffer in
            guard let buffer = makeBuffer(bytes: buffer.baseAddress!, length: buffer.count, options: options) else {
                throw BaseError.resourceCreationFailure
            }
            return TypedMTLBuffer(mtlBuffer: buffer)
        }
    }
}

// TODO: Unchecked sendable.
public struct TypedMTLBuffer<T>: Equatable {
    // TODO: Make private.
    public var base: MTLBuffer

    public init(mtlBuffer: MTLBuffer) {
        assert(_isPOD(T.self))
        self.base = mtlBuffer
    }

    public var count: Int {
        base.length / MemoryLayout<T>.size
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.base === rhs.base
    }

    func withMTLBuffer<R>(_ block: (MTLBuffer) throws -> R) rethrows -> R {
        try block(base)
    }
}

public extension TypedMTLBuffer {
    func withUnsafeBuffer<R>(_ block: (UnsafeBufferPointer<T>) throws -> R) rethrows -> R {
        let contents = base.contents()
        let pointer = contents.bindMemory(to: T.self, capacity: count)
        let buffer = UnsafeBufferPointer(start: pointer, count: count)
        return try block(buffer)
    }

    func labelled(_ label: String) -> Self {
        self.base.label = label
        return self
    }
}

extension MTLRenderCommandEncoder {
    // TODO: Offset
    func setVertexBuffer <T>(_ buffer: TypedMTLBuffer<T>, index: Int) {
        buffer.withMTLBuffer {
            setVertexBuffer($0, offset: 0, index: index)
        }
    }

    func setFragmentBuffer <T>(_ buffer: TypedMTLBuffer<T>, index: Int) {
        buffer.withMTLBuffer {
            setFragmentBuffer($0, offset: 0, index: index)
        }
    }
}

extension MTLComputeCommandEncoder {
    // TODO: Offset

    func setBuffer <T>(_ buffer: TypedMTLBuffer<T>, index: Int) {
        buffer.withMTLBuffer {
            setBuffer($0, offset: 0, index: index)
        }
    }
}
