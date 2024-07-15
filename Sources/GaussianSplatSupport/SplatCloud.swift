import CoreGraphicsSupport
import Metal
import MetalSupport
import simd
import SIMDSupport

// TODO: @unchecked Sendable
public struct SplatCloud: Equatable, @unchecked Sendable {
    public typealias Splat = SplatC
    public var splats: TypedMTLBuffer<Splat>
    public var indices: TypedMTLBuffer<UInt32>
    public var distances: TypedMTLBuffer<Float>
    public var cameraPosition: SIMD3<Float>
    public var boundingBox: (SIMD3<Float>, SIMD3<Float>)

    public init(device: MTLDevice, splats: TypedMTLBuffer<Splat>) throws {
        self.splats = splats

        let indices = (0 ..< splats.count).map { UInt32($0) }
        self.indices = try device.makeTypedBuffer(data: indices, options: .storageModeShared).labelled("Splats-Indices")
        let distances = Array(repeating: Float.zero, count: splats.count)
        self.distances = try device.makeTypedBuffer(data: distances, options: .storageModeShared).labelled("Splats-Distances")
        self.cameraPosition = [.nan, .nan, .nan]

        self.boundingBox = splats.withUnsafeBuffer { buffer in
            let positions = buffer.map { SIMD3<Float>($0.position) }
            // swiftlint:disable:next reduce_into
            let minimums = positions.reduce([.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude], min)
            // swiftlint:disable:next reduce_into
            let maximums = positions.reduce([-.greatestFiniteMagnitude, -.greatestFiniteMagnitude, -.greatestFiniteMagnitude], max)
            return (minimums, maximums)
        }
    }

    public init(device: MTLDevice, splats: [Splat]) throws {
        let mtlBuffer = try device.makeBuffer(bytesOf: splats, options: .storageModeShared)
        let typedMTLBuffer = TypedMTLBuffer<Splat>(mtlBuffer: mtlBuffer)
        try self.init(device: device, splats: typedMTLBuffer)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.splats == rhs.splats
            && lhs.indices == rhs.indices
            && lhs.distances == rhs.distances
            && lhs.cameraPosition == rhs.cameraPosition
    }
}

public extension SplatCloud {
    func center() -> SIMD3<Float> {
        (boundingBox.0 + boundingBox.1) / 2
    }
}

public struct SplatB: Equatable, Sendable {
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