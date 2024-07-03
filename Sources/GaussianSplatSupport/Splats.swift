import CoreGraphicsSupport
import Metal
import MetalSupport
import simd
import SIMDSupport

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

// MARK: -

public struct Splats <Splat>: Equatable {
    private var device: MTLDevice
    public var splats: TypedMTLBuffer<Splat> // TODO: Rename
    public var indices: TypedMTLBuffer<UInt32> // TODO: Rename
    public var distances: TypedMTLBuffer<Float>
    public var cameraPosition: SIMD3<Float>

    public init(device: MTLDevice, splats: TypedMTLBuffer<Splat>) throws {
        self.device = device
        self.splats = splats

        let indices = (0 ..< splats.count).map { UInt32($0) }
        self.indices = try device.makeTypedBuffer(data: indices, options: .storageModeShared).labelled("Splats-Indices")
        let distances = Array(repeating: Float.zero, count: splats.count)
        self.distances = try device.makeTypedBuffer(data: distances, options: .storageModeShared).labelled("Splats-Distances")
        self.cameraPosition = [.nan, .nan, .nan]
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.device === rhs.device
        && lhs.splats == rhs.splats
        && lhs.indices == rhs.indices
        && lhs.distances == rhs.distances
        && lhs.cameraPosition == rhs.cameraPosition
    }
}

// public extension Splats where Splat == SplatC {
//     func boundingBox() -> (SIMD3<Float>, SIMD3<Float>) {
//         withUnsafeSplatBuffer { buffer in
//             let positions = buffer.map({ SIMD3<Float>($0.position) })
//             let minimums = positions.reduce([.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude], min)
//             let maximums = positions.reduce([-.greatestFiniteMagnitude, -.greatestFiniteMagnitude, -.greatestFiniteMagnitude], max)
//             return (minimums, maximums)
//         }
//     }
//
//     func center() -> SIMD3<Float> {
//         let boundingBox = boundingBox()
//         return (boundingBox.0 + boundingBox.1) / 2
//     }
// }

extension SIMD3 where Scalar == Float {
    init(_ other: PackedHalf3) {
        self = SIMD3(Scalar(other.x), Scalar(other.y), Scalar(other.z))
    }
}

public struct SplatB: Equatable {
    public var position: PackedFloat3
    public var scale: PackedFloat3
    public var color: SIMD4<UInt8>
    public var rotation: SIMD4<UInt8>
}

public struct SplatC: Equatable {
    public var position: PackedHalf3
    public var color: PackedHalf4
    public var cov_a: PackedHalf3
    public var cov_b: PackedHalf3
}

public struct SplatD: Equatable {
    public var position: PackedFloat3
    public var scale: PackedFloat3
    public var color: SIMD4<Float>
    public var rotation: Rotation

    public init(position: PackedFloat3, scale: PackedFloat3, color: SIMD4<Float>, rotation: Rotation) {
        self.position = position
        self.scale = scale
        self.color = color
        self.rotation = rotation
    }
}
