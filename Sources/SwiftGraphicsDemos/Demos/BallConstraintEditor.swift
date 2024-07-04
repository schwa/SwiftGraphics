import Fields3D
import SIMDSupport
import SwiftUI

struct BallConstraintEditor: View {
    @Binding
    var ballConstraint: BallConstraint

    var body: some View {
        TextField("Radius", value: $ballConstraint.radius, format: .number)
        //        TextField("Look AT", value: $ballConstraint.lookAt, format: .vector)
        RollPitchYawEditor($ballConstraint.rollPitchYaw)
    }
}
