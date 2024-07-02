import SwiftUI
import SwiftGraphicsSupport
import Fields3D

struct BallConstraintEditor: View {
    @Binding
    var ballConstraint: BallConstraint

    var body: some View {
        TextField("Radius", value: $ballConstraint.radius, format: .number)
        //        TextField("Look AT", value: $ballConstraint.lookAt, format: .vector)
        RollPitchYawEditor($ballConstraint.rollPitchYaw)
    }
}
