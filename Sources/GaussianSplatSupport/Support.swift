import BaseSupport
import Foundation
@preconcurrency import Metal
import simd
import SIMDSupport

// swiftlint:disable force_unwrapping

public func max(lhs: PackedFloat3, rhs: PackedFloat3) -> PackedFloat3 {
    [max(lhs[0], rhs[0]), max(lhs[1], rhs[1]), max(lhs[2], rhs[2])]
}

public func min(lhs: PackedFloat3, rhs: PackedFloat3) -> PackedFloat3 {
    [min(lhs[0], rhs[0]), min(lhs[1], rhs[1]), min(lhs[2], rhs[2])]
}

public extension Collection where Element == PackedFloat3 {
    var bounds: (min: PackedFloat3, max: PackedFloat3) {
        (
            // swiftlint:disable:next reduce_into
            reduce([Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude], GaussianSplatSupport.min),
            // swiftlint:disable:next reduce_into
            reduce([-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude], GaussianSplatSupport.max)
        )
    }
}

public extension Bundle {
    // GaussianSplatTests.xctest/Contents/Resources/SwiftGraphics_GaussianSplatSupport.bundle

    func peerBundle(named name: String, withExtension extension: String? = nil) -> Bundle? {
        let parentDirectory = bundleURL.deletingLastPathComponent()
        if let `extension` {
            return Bundle(url: parentDirectory.appendingPathComponent(name + "." + `extension`))
        }
        else {
            return Bundle(url: parentDirectory.appendingPathComponent(name))
        }
    }

    static let gaussianSplatShaders: Bundle = {
        Bundle.module.peerBundle(named: "SwiftGraphics_GaussianSplatShaders", withExtension: "bundle").forceUnwrap("Could not find bundle.")

        //        print(Bundle.module)
        //        if let shadersBundleURL = Bundle.main.url(forResource: "SwiftGraphics_GaussianSplatShaders", withExtension: "bundle"), let bundle = Bundle(url: shadersBundleURL) {
        //            return bundle
        //        }
        //        // Fail.
        //        fatalError("Could not find shaders bundle")
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

public struct TypedMTLBuffer<T>: Equatable, Sendable {
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
    func withUnsafeBufferPointer<R>(_ block: (UnsafeBufferPointer<T>) throws -> R) rethrows -> R {
        let contents = base.contents()
        let pointer = contents.bindMemory(to: T.self, capacity: count)
        let buffer = UnsafeBufferPointer(start: pointer, count: count)
        return try block(buffer)
    }

    func withUnsafeMutableBufferPointer<R>(_ block: (UnsafeMutableBufferPointer<T>) throws -> R) rethrows -> R {
        let contents = base.contents()
        let pointer = contents.bindMemory(to: T.self, capacity: count)
        let buffer = UnsafeMutableBufferPointer(start: pointer, count: count)
        return try block(buffer)
    }

    func labelled(_ label: String) -> Self {
        self.base.label = label
        return self
    }
}

extension MTLRenderCommandEncoder {
    // TODO: Offset
    func setVertexBuffer <T>(_ buffer: TypedMTLBuffer<T>, offset: Int, index: Int) {
        buffer.withMTLBuffer {
            setVertexBuffer($0, offset: offset * MemoryLayout<T>.stride, index: index)
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

public struct TupleBuffered<Element> {
    var elements: [Element]

    public init(elements: [Element]) {
        self.elements = elements
    }

    public mutating func rotate() {
        let first = elements.removeFirst()
        elements.append(first)
    }

    public subscript(_ index: Int) -> Element {
        get {
            elements[index]
        }
        set {
            elements[index] = newValue
        }
    }
}

extension TupleBuffered: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.elements = elements
    }
}

extension TupleBuffered: Sendable where Element: Sendable {
}

extension TupleBuffered: Equatable where Element: Equatable {
}

extension TupleBuffered: Hashable where Element: Hashable {
}
