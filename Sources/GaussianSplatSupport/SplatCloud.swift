import GaussianSplatShaders
import Metal
import MetalSupport
import simd
import SIMDSupport

// TODO: @unchecked Sendable
public struct SplatCloud: Equatable, @unchecked Sendable {
    public typealias Splat = SplatC
    public var splats: TypedMTLBuffer<Splat>
    public var indexedDistances: TypedMTLBuffer<IndexedDistance>
    public var cameraPosition: SIMD3<Float>
    public var boundingBox: (SIMD3<Float>, SIMD3<Float>)

    public init(device: MTLDevice, splats: TypedMTLBuffer<Splat>) throws {
        self.splats = splats

        let indexedDistances = (0 ..< splats.count).map { IndexedDistance(index: UInt32($0), distance: 0.0) }

        self.indexedDistances = try device.makeTypedBuffer(data: indexedDistances, options: .storageModeShared).labelled("Splats-IndexDistances-1") //
        self.cameraPosition = [.nan, .nan, .nan]

        self.boundingBox = splats.withUnsafeBufferPointer { buffer in
            let positions = buffer.map { SIMD3<Float>($0.position) }
            // swiftlint:disable:next reduce_into
            let minimums = positions.reduce([.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude], min)
            // swiftlint:disable:next reduce_into
            let maximums = positions.reduce([-.greatestFiniteMagnitude, -.greatestFiniteMagnitude, -.greatestFiniteMagnitude], max)
            return (minimums, maximums)
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.splats == rhs.splats
            && lhs.indexedDistances == rhs.indexedDistances
            && lhs.cameraPosition == rhs.cameraPosition
    }
}

public extension SplatCloud {
    init(device: MTLDevice, splats: [Splat]) throws {
        assert(!splats.isEmpty)
        let mtlBuffer = try device.makeBuffer(bytesOf: splats, options: .storageModeShared)
        mtlBuffer.label = "Splats-1"
        let typedMTLBuffer = TypedMTLBuffer<Splat>(mtlBuffer: mtlBuffer)
        try self.init(device: device, splats: typedMTLBuffer)
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

// Metal Debugger: half3 position, half4 color, half3 cov_a, half3 cov_b
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
