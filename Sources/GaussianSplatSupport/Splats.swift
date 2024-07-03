import CoreGraphicsSupport
import Metal
import simd
import SIMDSupport

public struct Splats <Splat>: Equatable {
    public var splatBuffer: MTLBuffer
    public var indexBuffer: MTLBuffer

    public init(splatBuffer: MTLBuffer, indexBuffer: MTLBuffer) {
        self.splatBuffer = splatBuffer
        self.indexBuffer = indexBuffer
    }

    public func withUnsafeSplatBuffer<R>(_ block: (UnsafeBufferPointer<Splat>) throws -> R) rethrows -> R {
        let contents = splatBuffer.contents()
        let count = splatBuffer.length / MemoryLayout<Splat>.size
        let pointer = contents.bindMemory(to: Splat.self, capacity: count)
        let buffer = UnsafeBufferPointer(start: pointer, count: count)
        return try block(buffer)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.splatBuffer === rhs.splatBuffer && lhs.indexBuffer === rhs.indexBuffer
    }
}

public extension Splats where Splat == SplatC {
    func boundingBox() -> (SIMD3<Float>, SIMD3<Float>) {
        withUnsafeSplatBuffer { buffer in
            let positions = buffer.map({ SIMD3<Float>($0.position) })
            let minimums = positions.reduce([.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude], min)
            let maximums = positions.reduce([-.greatestFiniteMagnitude, -.greatestFiniteMagnitude, -.greatestFiniteMagnitude], max)
            return (minimums, maximums)
        }
    }

    func center() -> SIMD3<Float> {
        let boundingBox = boundingBox()
        return (boundingBox.0 + boundingBox.1) / 2
    }
}

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
