import Foundation
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

public struct RollPitchYawEditor: View {
    @Binding
    var rollPitchYaw: RollPitchYaw

    public init(_ rollPitchYaw: Binding<RollPitchYaw>) {
        self._rollPitchYaw = rollPitchYaw
    }

    public var body: some View {
        TextField("Roll", value: $rollPitchYaw.roll, format: .angle)
        TextField("Pitch", value: $rollPitchYaw.pitch, format: .angle)
        TextField("Yaw", value: $rollPitchYaw.yaw, format: .angle)
    }
}

#Preview {
    @Previewable @State var rollPitchYaw = RollPitchYaw()
    Form {
        RollPitchYawEditor($rollPitchYaw)
    }
}
