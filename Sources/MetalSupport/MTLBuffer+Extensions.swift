import BaseSupport
import Metal

public extension MTLDevice {
    // TODO: Rename
    func makeBufferEx(bytes pointer: UnsafeRawPointer, length: Int, options: MTLResourceOptions = []) throws -> MTLBuffer {
        guard let buffer = makeBuffer(bytes: pointer, length: length, options: options) else {
            throw BaseError.resourceCreationFailure
        }
        return buffer
    }

    // TODO: Rename
    func makeBufferEx(length: Int, options: MTLResourceOptions = []) throws -> MTLBuffer {
        guard let buffer = makeBuffer(length: length, options: options) else {
            throw BaseError.resourceCreationFailure
        }
        return buffer
    }

    func makeBuffer(data: Data, options: MTLResourceOptions) throws -> MTLBuffer {
        try data.withUnsafeBytes { buffer in
            let baseAddress = buffer.baseAddress.forceUnwrap("No baseAddress.")
            guard let buffer = makeBuffer(bytes: baseAddress, length: buffer.count, options: options) else {
                throw BaseError.resourceCreationFailure
            }
            return buffer
        }
    }

    func makeBuffer(bytesOf content: some Any, options: MTLResourceOptions) throws -> MTLBuffer {
        try withUnsafeBytes(of: content) { buffer in
            let baseAddress = buffer.baseAddress.forceUnwrap("No baseAddress.")
            guard let buffer = makeBuffer(bytes: baseAddress, length: buffer.count, options: options) else {
                throw BaseError.resourceCreationFailure
            }
            return buffer
        }
    }

    func makeBuffer(bytesOf content: [some Any], options: MTLResourceOptions) throws -> MTLBuffer {
        try content.withUnsafeBytes { buffer in
            let baseAddress = buffer.baseAddress.forceUnwrap("No baseAddress.")
            guard let buffer = makeBuffer(bytes: baseAddress, length: buffer.count, options: options) else {
                throw BaseError.resourceCreationFailure
            }
            return buffer
        }
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
