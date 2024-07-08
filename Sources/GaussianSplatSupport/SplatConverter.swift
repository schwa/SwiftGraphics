import CoreGraphicsSupport
import simd
import SIMDSupport

public extension SplatB {
    init(_ other: SplatD) {
        let color = SIMD4<UInt8>(other.color * 255)
        let rotation_vector = other.rotation.quaternion.vectorRealFirst
        let rotation = ((rotation_vector / rotation_vector.length) * 128 + 128).clamped(to: 0...255)
        self = SplatB(position: other.position, scale: other.scale, color: color, rotation: SIMD4<UInt8>(rotation))
    }
}

//extension DotSplatSceneReader.EncodedSplatPoint {
//    var splatScenePoint: SplatScenePoint {
//        SplatScenePoint(position: position,
//                        normal: nil,
//                        color: .linearUInt8(color.x, color.y, color.z),
//                        opacity: .linearUInt8(color.w),
//                        scale: .linearFloat(scales.x, scales.y, scales.z),
//                        rotation: simd_quatf(vector: SIMD4(x: Float(rot[1]) - 128,
//                                                           y: Float(rot[2]) - 128,
//                                                           z: Float(rot[3]) - 128,
//                                                           w: Float(rot[0]) - 128)).normalized)
//    }
//}

//    init(position: SIMD3<Float>,
//         color: SIMD4<Float>,
//         scale: SIMD3<Float>,
//         rotation: simd_quatf) {
//        let transform = simd_float3x3(rotation) * simd_float3x3(diagonal: scale)
//        let cov3D = transform * transform.transpose
//        self.init(position: MTLPackedFloat3Make(position.x, position.y, position.z),
//                  color: SplatRenderer.PackedRGBHalf4(r: Float16(color.x), g: Float16(color.y), b: Float16(color.z), a: Float16(color.w)),
//                  covA: SplatRenderer.PackedHalf3(x: Float16(cov3D[0, 0]), y: Float16(cov3D[0, 1]), z: Float16(cov3D[0, 2])),
//                  covB: SplatRenderer.PackedHalf3(x: Float16(cov3D[1, 1]), y: Float16(cov3D[1, 2]), z: Float16(cov3D[2, 2])))
//    }

public extension SplatC {
    init(_ other: SplatB) {
        let position = PackedHalf3(SIMD3<Float>(other.position))

        // TODO: SRGB to Linear
        let color = PackedHalf4(x: Float16(other.color.x) / 255, y: Float16(other.color.y) / 255, z: Float16(other.color.z) / 255, w: Float16(other.color.w) / 255)

        let rotation = simd_quatf(vector: SIMD4(x: Float(other.rotation[1]) - 128,
                                                y: Float(other.rotation[2]) - 128,
                                                z: Float(other.rotation[3]) - 128,
                                                w: Float(other.rotation[0]) - 128)).normalized
        let transform = simd_float3x3(rotation) * simd_float3x3(diagonal: SIMD3<Float>(other.scale))
        let cov3D = transform * transform.transpose
        let cov_a = PackedHalf3(x: Float16(cov3D[0, 0]), y: Float16(cov3D[0, 1]), z: Float16(cov3D[0, 2]))
        let cov_b = PackedHalf3(x: Float16(cov3D[1, 1]), y: Float16(cov3D[1, 2]), z: Float16(cov3D[2, 2]))

        self = SplatC(position: position, color: color, cov_a: cov_a, cov_b: cov_b)
    }

    init(_ other: SplatD) {
        let transform = simd_float3x3(other.rotation.quaternion) * simd_float3x3(diagonal: SIMD3<Float>(other.scale))
        let cov3D = transform * transform.transpose
        let cov_a = PackedHalf3(x: Float16(cov3D[0, 0]), y: Float16(cov3D[0, 1]), z: Float16(cov3D[0, 2]))
        let cov_b = PackedHalf3(x: Float16(cov3D[1, 1]), y: Float16(cov3D[1, 2]), z: Float16(cov3D[2, 2]))

        self = SplatC(position: PackedHalf3(SIMD3<Float>(other.position)), color: PackedHalf4(other.color), cov_a: cov_a, cov_b: cov_b)
    }
}

public func convert_b_to_c <C>(_ splats: C) -> [SplatC] where C: Collection, C.Element == SplatB {
    assert(MemoryLayout<SplatC>.size == 26)
    assert(MemoryLayout<SplatB>.size == 32)
    return splats.map { splat in
        SplatC(splat)
    }
}
