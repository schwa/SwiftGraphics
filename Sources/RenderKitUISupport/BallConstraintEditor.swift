import Fields3D
import SIMDSupport
import SwiftUI

public struct BallConstraintEditor: View {
    @Binding
    var ballConstraint: BallConstraint

    public init(ballConstraint: Binding<BallConstraint>) {
        self._ballConstraint = ballConstraint
    }

    public var body: some View {
        TextField("Radius", value: $ballConstraint.radius, format: .number)
        //        TextField("Look AT", value: $ballConstraint.lookAt, format: .vector)
        RollPitchYawEditor($ballConstraint.rollPitchYaw)
    }
}
