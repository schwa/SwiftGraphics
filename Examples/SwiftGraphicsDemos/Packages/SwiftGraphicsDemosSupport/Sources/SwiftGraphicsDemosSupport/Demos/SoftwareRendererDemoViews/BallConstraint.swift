import SwiftUI
import simd
import SIMDSupport

struct BallConstraint: Equatable {
    var radius: Float = -5
    var lookAt: SIMD3<Float> = .zero
    var rollPitchYaw: RollPitchYaw = .zero

    var transform: simd_float4x4 {
        rollPitchYaw.matrix * simd_float4x4(translate: [0, 0, radius])
    }
}

struct BallConstraintEditor: View {
    @Binding
    var ballConstraint: BallConstraint

    var body: some View {
        TextField("Radius", value: $ballConstraint.radius, format: .number)
        TextField("Look AT", value: $ballConstraint.lookAt, format: .vector)
        TextField("Pitch", value: $ballConstraint.rollPitchYaw.pitch, format: .angle)
        TextField("Yaw", value: $ballConstraint.rollPitchYaw.yaw, format: .angle)
    }
}
