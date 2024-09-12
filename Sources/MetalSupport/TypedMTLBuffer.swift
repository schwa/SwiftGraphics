import BaseSupport
@preconcurrency import Metal

/// A type-safe wrapper around `MTLBuffer` for managing Metal buffers with a specific element type.
///
/// `TypedMTLBuffer` provides a convenient way to work with Metal buffers while maintaining type safety.
/// It encapsulates an `MTLBuffer` and provides methods to safely access and manipulate its contents.
///
/// - Important: This type conforms to `Sendable`. However, this conformance is only valid if the
///   underlying `MTLBuffer` is not reused elsewhere. Ensure that the `MTLBuffer` is uniquely owned
///   by this `TypedMTLBuffer` instance to maintain thread safety when sending across concurrency domains.
/// - Note: The generic type `Element` should be a POD (Plain Old Data) type.
public struct TypedMTLBuffer<Element>: Sendable {
    public private(set) var count: Int

    /// The underlying Metal buffer.
    private var base: MTLBuffer?

    /// Initializes a new `TypedMTLBuffer` with the given Metal buffer.
    ///
    /// - Parameter mtlBuffer: The Metal buffer to wrap.
    /// - Precondition: The generic type `Element` must be a POD type.
    public init(mtlBuffer: MTLBuffer?, count: Int) {
        assert(_isPOD(Element.self))
        self.base = mtlBuffer
        self.count = count
    }

    public init() {
        self.base = nil
        self.count = 0
    }

    public var capacity: Int {
        (base?.length ?? 0) / MemoryLayout<Element>.stride
    }
}

extension TypedMTLBuffer: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.count == rhs.count && lhs.base === rhs.base
    }
}

extension TypedMTLBuffer: CustomDebugStringConvertible {
    public var debugDescription: String {
        "TypedMTLBuffer<\(type(of: Element.self))>(count: \(count), capacity: \(capacity), base.label: \(base?.label), base.length: \(base?.length))"
    }
}

// MARK: -

public extension TypedMTLBuffer {
    var unsafeBase: MTLBuffer? {
        base
    }

    /// Provides temporary access to the underlying `MTLBuffer`.
    ///
    /// - Parameter block: A closure that takes an `MTLBuffer` and returns a value.
    /// - Returns: The value returned by the `block`.
    /// - Throws: Rethrows any error thrown by the `block`.
    func withUnsafeMTLBuffer<R>(_ block: (MTLBuffer?) throws -> R) rethrows -> R {
        try block(base)
    }

    /// Provides unsafe read-only access to the buffer's contents.
    ///
    /// - Parameter block: A closure that takes an `UnsafeBufferPointer<T>` and returns a value.
    /// - Returns: The value returned by the `block`.
    /// - Throws: Rethrows any error thrown by the `block`.
    func withUnsafeBufferPointer<R>(_ block: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R {
        if let base {
            let contents = base.contents()
            let pointer = contents.bindMemory(to: Element.self, capacity: count)
            let buffer = UnsafeBufferPointer(start: pointer, count: count)
            return try block(buffer)
        }
        else {
            return try block(UnsafeBufferPointer<Element>(start: nil, count: 0))
        }
    }

    /// Provides unsafe mutable access to the buffer's contents.
    ///
    /// - Parameter block: A closure that takes an `UnsafeMutableBufferPointer<T>` and returns a value.
    /// - Returns: The value returned by the `block`.
    /// - Throws: Rethrows any error thrown by the `block`.
    func withUnsafeMutableBufferPointer<R>(_ block: (UnsafeMutableBufferPointer<Element>?) throws -> R) rethrows -> R {
        if let base {
            let contents = base.contents()
            let pointer = contents.bindMemory(to: Element.self, capacity: count)
            let buffer = UnsafeMutableBufferPointer(start: pointer, count: count)
            return try block(buffer)
        }
        else {
            return try block(UnsafeMutableBufferPointer<Element>(start: nil, count: 0))
        }
    }

    /// Sets a label for the underlying Metal buffer.
    ///
    /// - Parameter label: The label to set.
    /// - Returns: The `TypedMTLBuffer` instance with the updated label.
    func labelled(_ label: String) -> Self {
        base?.label = label
        return self
    }
}

public extension TypedMTLBuffer {
    mutating func append(contentsOf elements: [Element]) throws {
        if count + elements.count > capacity {
            throw BaseError.error(.overflow)
        }
        guard let base else {
            throw BaseError.error(.overflow)
        }

        elements.withUnsafeBytes { buffer in
            let destination = base.contents().advanced(by: count)
            buffer.copyBytes(to: .init(start: destination, count: buffer.count))
        }
        count += elements.count
    }
}

// MARK: -

public extension MTLDevice {
    /// Creates a `TypedMTLBuffer` from the given data.
    ///
    /// - Parameters:
    ///   - data: The data to copy into the new buffer.
    ///   - options: Options for the new buffer. Default is an empty option set.
    /// - Returns: A new `TypedMTLBuffer` containing the specified data.
    /// - Throws: `BaseError.illegalValue` if the data size is not a multiple of the size of `Element`.
    ///           `BaseError.resourceCreationFailure` if the buffer creation fails.
    func makeTypedBuffer<Element>(data: Data, options: MTLResourceOptions = []) throws -> TypedMTLBuffer<Element> {
        if !data.count.isMultiple(of: MemoryLayout<Element>.stride) {
            throw BaseError.error(.illegalValue)
        }
        let count = data.count / MemoryLayout<Element>.stride
        return try data.withUnsafeBytes { buffer in
            guard let buffer = makeBuffer(bytes: buffer.baseAddress!, length: buffer.count, options: options) else {
                throw BaseError.error(.resourceCreationFailure)
            }
            return TypedMTLBuffer(mtlBuffer: buffer, count: count)
        }
    }

    /// Creates a `TypedMTLBuffer` from the given array.
    ///
    /// - Parameters:
    ///   - data: The array to copy into the new buffer.
    ///   - options: Options for the new buffer. Default is an empty option set.
    /// - Returns: A new `TypedMTLBuffer` containing the specified data.
    /// - Throws: `BaseError.resourceCreationFailure` if the buffer creation fails.
    func makeTypedBuffer<Element>(data: [Element], options: MTLResourceOptions = []) throws -> TypedMTLBuffer<Element> {
        if data.isEmpty {
            return TypedMTLBuffer<Element>()
        }
        else {
            return try data.withUnsafeBytes { buffer in
                guard let buffer = makeBuffer(bytes: buffer.baseAddress!, length: buffer.count, options: options) else {
                    throw BaseError.error(.resourceCreationFailure)
                }
                return TypedMTLBuffer<Element>(mtlBuffer: buffer, count: data.count)
            }
        }
    }

    func makeTypedBuffer<Element>(element: Element.Type, capacity: Int, options: MTLResourceOptions = []) throws -> TypedMTLBuffer<Element> {
        // swiftlint:disable:next empty_count
        if capacity == 0 {
            return TypedMTLBuffer<Element>()
        }
        else {
            guard let buffer = makeBuffer(length: MemoryLayout<Element>.stride * capacity, options: options) else {
                throw BaseError.error(.resourceCreationFailure)
            }
            return TypedMTLBuffer(mtlBuffer: buffer, count: 0)
        }
    }

    func makeTypedBuffer<Element>(capacity: Int, options: MTLResourceOptions = []) throws -> TypedMTLBuffer<Element> {
        try makeTypedBuffer(element: Element.self, capacity: capacity, options: options)
    }
}

// MARK: -

public extension MTLRenderCommandEncoder {
    /// Sets a vertex buffer for the render command encoder.
    ///
    /// - Parameters:
    ///   - buffer: The `TypedMTLBuffer` to set as the vertex buffer.
    ///   - offset: The offset in elements from the start of the buffer. This value is multiplied by `MemoryLayout<T>.stride` to calculate the byte offset.
    ///   - index: The index into the buffer argument table.
    func setVertexBuffer <T>(_ buffer: TypedMTLBuffer<T>, offset: Int, index: Int) {
        buffer.withUnsafeMTLBuffer {
            setVertexBuffer($0, offset: offset * MemoryLayout<T>.stride, index: index)
        }
    }

    /// Sets a fragment buffer for the render command encoder.
    ///
    /// - Parameters:
    ///   - buffer: The `TypedMTLBuffer` to set as the fragment buffer.
    ///   - offset: The offset in elements from the start of the buffer. This value is multiplied by `MemoryLayout<T>.stride` to calculate the byte offset.
    ///   - index: The index into the buffer argument table.
    func setFragmentBuffer <T>(_ buffer: TypedMTLBuffer<T>, offset: Int, index: Int) {
        buffer.withUnsafeMTLBuffer {
            setFragmentBuffer($0, offset: offset * MemoryLayout<T>.stride, index: index)
        }
    }
}

public extension MTLComputeCommandEncoder {
    /// Sets a buffer for the compute command encoder.
    ///
    /// - Parameters:
    ///   - buffer: The `TypedMTLBuffer` to set.
    ///   - offset: The offset in elements from the start of the buffer. This value is multiplied by `MemoryLayout<T>.stride` to calculate the byte offset.
    ///   - index: The index into the buffer argument table.
    func setBuffer <T>(_ buffer: TypedMTLBuffer<T>, offset: Int, index: Int) {
        buffer.withUnsafeMTLBuffer {
            setBuffer($0, offset: offset * MemoryLayout<T>.stride, index: index)
        }
    }
}
