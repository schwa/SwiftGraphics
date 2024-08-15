import Metal

// swiftlint:disable force_unwrapping

public extension MTLArgumentEncoder {
    func setBytes(of value: some Any, index: Int) {
        withUnsafeBytes(of: value) { buffer in
            let dest = UnsafeMutableRawBufferPointer(start: constantData(at: index), count: encodedLength)
            buffer.copyBytes(to: dest)
        }
    }
}

// MARK: -

public extension MTLComputeCommandEncoder {
    func setBytes(_ bytes: UnsafeRawBufferPointer, index: Int) {
        setBytes(bytes.baseAddress!, length: bytes.count, index: index)
    }

    func setBytes(of value: some Any, index: Int) {
        withUnsafeBytes(of: value) { buffer in
            setBytes(buffer, index: index)
        }
    }

    func setBytes(of array: [some Any], index: Int) {
        array.withUnsafeBytes { buffer in
            setBytes(buffer, index: index)
        }
    }
}

// MARK: -

public extension MTLRenderCommandEncoder {
    func setVertexBytes(_ bytes: UnsafeRawBufferPointer, index: Int) {
        setVertexBytes(bytes.baseAddress!, length: bytes.count, index: index)
    }

    func setVertexBytes(of value: some Any, index: Int) {
        withUnsafeBytes(of: value) { buffer in
            setVertexBytes(buffer, index: index)
        }
    }

    func setVertexBytes(of value: [some Any], index: Int) {
        value.withUnsafeBytes { buffer in
            setVertexBytes(buffer, index: index)
        }
    }

    // MARK: -

    func setFragmentBytes(_ bytes: UnsafeRawBufferPointer, index: Int) {
        setFragmentBytes(bytes.baseAddress!, length: bytes.count, index: index)
    }

    func setFragmentBytes(of value: some Any, index: Int) {
        withUnsafeBytes(of: value) { buffer in
            setFragmentBytes(buffer, index: index)
        }
    }

    func setFragmentBytes(of value: [some Any], index: Int) {
        value.withUnsafeBytes { buffer in
            setFragmentBytes(buffer, index: index)
        }
    }

    // MARK: -

    func setObjectBytes(_ bytes: UnsafeRawBufferPointer, index: Int) {
        setObjectBytes(bytes.baseAddress!, length: bytes.count, index: index)
    }

    func setObjectBytes(of value: some Any, index: Int) {
        withUnsafeBytes(of: value) { buffer in
            setObjectBytes(buffer, index: index)
        }
    }

    func setObjectBytes(of value: [some Any], index: Int) {
        value.withUnsafeBytes { buffer in
            setObjectBytes(buffer, index: index)
        }
    }

    // MARK: -

    func setMeshBytes(_ bytes: UnsafeRawBufferPointer, index: Int) {
        setMeshBytes(bytes.baseAddress!, length: bytes.count, index: index)
    }

    func setMeshBytes(of value: some Any, index: Int) {
        withUnsafeBytes(of: value) { buffer in
            setMeshBytes(buffer, index: index)
        }
    }

    func setMeshBytes(of value: [some Any], index: Int) {
        value.withUnsafeBytes { buffer in
            setMeshBytes(buffer, index: index)
        }
    }
}
