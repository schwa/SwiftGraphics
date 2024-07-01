import CoreGraphicsSupport
import SIMDSupport
import simd


struct SplatB: Equatable {
    var position: PackedFloat3
    var scale: PackedFloat3
    var color: SIMD4<UInt8>
    var rotation: SIMD4<UInt8>
}

struct SplatD: Equatable {
    var position: PackedFloat3
    var scale: PackedFloat3
    var color: SIMD4<Float>
    var rotation: Rotation
}

//struct SplatC: Equatable {
//    var position: PackedHalf3
//    var color: PackedHalf4
//    var cov_a: PackedHalf3
//    var cov_b: PackedHalf3
//};

//buffer.write(
//           ((rot / np.linalg.norm(rot)) * 128 + 128)
//           .clip(0, 255)
//           .astype(np.uint8)
//           .tobytes()
//       )

extension SplatB {
    init(_ other: SplatD) {
        let color = SIMD4<UInt8>(other.color * 255)
        let rotation_vector = other.rotation.quaternion.vectorRealFirst
        let rotation = ((rotation_vector / rotation_vector.length) * 128 + 128).clamped(to: 0...255)
        self = SplatB(position: other.position, scale: other.scale, color: color, rotation: SIMD4<UInt8>(rotation))
    }
}

extension simd_quatf {
    var vectorRealFirst: simd_float4 {
        return [vector.w, vector.x, vector.y, vector.z]
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


extension SplatC {
    init(_ other: SplatB) {
        let rotation = simd_quatf(vector: SIMD4(x: Float(other.rotation[1]) - 128,
                                                y: Float(other.rotation[2]) - 128,
                                                z: Float(other.rotation[3]) - 128,
                                                w: Float(other.rotation[0]) - 128)).normalized

        let transform = simd_float3x3(rotation) * simd_float3x3(diagonal: SIMD3<Float>(other.scale))
        let cov3D = transform * transform.transpose
        let cov_a = PackedHalf3(x: Float16(cov3D[0, 0]), y: Float16(cov3D[0, 1]), z: Float16(cov3D[0, 2]))
        let cov_b = PackedHalf3(x: Float16(cov3D[1, 1]), y: Float16(cov3D[1, 2]), z: Float16(cov3D[2, 2]))

        // TODO: SRGB to Linear
        let color = PackedHalf4(x: Float16(other.color.x) / 255, y: Float16(other.color.y) / 255, z: Float16(other.color.z) / 255, w: Float16(other.color.w) / 255)

        self = SplatC(position: PackedHalf3(SIMD3<Float>(other.position)), color: color, cov_a: cov_a, cov_b: cov_b)
    }

    init(_ other: SplatD) {
        let transform = simd_float3x3(other.rotation.quaternion) * simd_float3x3(diagonal: SIMD3<Float>(other.scale))
        let cov3D = transform * transform.transpose
        let cov_a = PackedHalf3(x: Float16(cov3D[0, 0]), y: Float16(cov3D[0, 1]), z: Float16(cov3D[0, 2]))
        let cov_b = PackedHalf3(x: Float16(cov3D[1, 1]), y: Float16(cov3D[1, 2]), z: Float16(cov3D[2, 2]))

        self = SplatC(position: PackedHalf3(SIMD3<Float>(other.position)), color: PackedHalf4(other.color), cov_a: cov_a, cov_b: cov_b)

    }
}

func convert <C>(_ splats: C) -> [SplatC] where C: Collection, C.Element == SplatB {
    print(MemoryLayout<SplatC>.size)
    print(MemoryLayout<SplatB>.size)
    assert(MemoryLayout<SplatC>.size == 26)
    assert(MemoryLayout<SplatB>.size == 32)
    return splats.map { splat in
        SplatC(splat)
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
