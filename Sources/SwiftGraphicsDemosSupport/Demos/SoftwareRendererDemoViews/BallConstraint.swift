import simd
import SIMDSupport
import SwiftUI

struct BallConstraint: Equatable {
    var radius: Float = -5
//    var lookAt: SIMD3<Float> = .zero
    var rollPitchYaw: RollPitchYaw = .zero

    var transform: Transform {
        Transform((rollPitchYaw.matrix4x4 * simd_float4x4(translate: [0, 0, radius])))
    }
}
