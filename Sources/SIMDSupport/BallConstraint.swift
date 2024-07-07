import simd
import SwiftUI

public struct BallConstraint: Equatable {
    public var radius: Float
    //    var lookAt: SIMD3<Float> = .zero
    public var rollPitchYaw: RollPitchYaw

    public var transform: Transform {
        Transform((rollPitchYaw.matrix4x4 * simd_float4x4(translate: [0, 0, radius])))
    }

    public init(radius: Float = 5, rollPitchYaw: RollPitchYaw = .zero) {
        self.radius = radius
        self.rollPitchYaw = rollPitchYaw
    }
}
