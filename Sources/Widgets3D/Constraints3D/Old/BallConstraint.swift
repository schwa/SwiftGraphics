import simd
import SIMDSupport
import SwiftUI

@available(*, deprecated, message: "Deprecated")
public struct BallConstraint: Equatable {
    public var radius: Float
    public var lookAt: SIMD3<Float>
    public var rollPitchYaw: RollPitchYaw

    public var transform: Transform {
        // TODO: Is order correct (probably not)
        Transform((rollPitchYaw.toMatrix4x4(order: .rollPitchYaw) * simd_float4x4(translate: [0, 0, radius])))
    }

    public init(radius: Float = 5, lookAt: SIMD3<Float> = .zero, rollPitchYaw: RollPitchYaw = .zero) {
        self.radius = radius
        self.lookAt = lookAt
        self.rollPitchYaw = rollPitchYaw
    }
}
