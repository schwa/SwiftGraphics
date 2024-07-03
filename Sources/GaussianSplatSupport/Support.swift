import CoreGraphicsSupport
import Foundation
import simd
import SIMDSupport

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

extension FloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        clamp(self, in: range)
    }
}

extension SIMD4 where Scalar == Float {
    func clamped(to range: ClosedRange<Scalar>) -> Self {
        [x.clamped(to: range), y.clamped(to: range), z.clamped(to: range), w.clamped(to: range)]
    }
}

extension Bundle {
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
            throw MetalSupportError.illegalValue
        }
        return try data.withUnsafeBytes { buffer in
            guard let buffer = makeBuffer(bytes: buffer.baseAddress!, length: buffer.count, options: options) else {
                throw MetalSupportError.resourceCreationFailure
            }
            return TypedMTLBuffer(mtlBuffer: buffer)
        }
    }

    func makeTypedBuffer<T>(data: [T], options: MTLResourceOptions = []) throws -> TypedMTLBuffer<T> {
        try data.withUnsafeBytes { buffer in
            guard let buffer = makeBuffer(bytes: buffer.baseAddress!, length: buffer.count, options: options) else {
                throw MetalSupportError.resourceCreationFailure
            }
            return TypedMTLBuffer(mtlBuffer: buffer)
        }
    }
}

public struct TypedMTLBuffer<T>: Equatable {
    public var base: MTLBuffer

    public init(mtlBuffer: MTLBuffer) {
        assert(_isPOD(T.self))
        self.base = mtlBuffer
    }

    public var count: Int {
        base.length / MemoryLayout<T>.size
    }

    public func withUnsafeBuffer<R>(_ block: (UnsafeBufferPointer<T>) throws -> R) rethrows -> R {
        let contents = base.contents()
        let pointer = contents.bindMemory(to: T.self, capacity: count)
        let buffer = UnsafeBufferPointer(start: pointer, count: count)
        return try block(buffer)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.base === rhs.base
    }
}

extension TypedMTLBuffer {
    func labelled(_ label: String) -> Self {
        self.base.label = label
        return self
    }
}
