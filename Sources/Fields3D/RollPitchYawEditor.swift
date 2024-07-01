import CoreGraphicsSupport
import Foundation
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

public struct RollPitchYawEditor: View {
    @Binding
    var rollPitchYaw: RollPitchYaw

    @State
    private var showsMatrix: Bool = false

    @State
    private var target: RollPitchYaw.Target = .object

    public init(_ rollPitchYaw: Binding<RollPitchYaw>) {
        self._rollPitchYaw = rollPitchYaw
    }

    public var body: some View {
        TextField("Roll", value: $rollPitchYaw.roll, format: .angle)
        TextField("Pitch", value: $rollPitchYaw.pitch, format: .angle)
        TextField("Yaw", value: $rollPitchYaw.yaw, format: .angle)
        Toggle("Show Matrix", isOn: $showsMatrix)
        if showsMatrix {
            Picker("Mode", selection: $target) {
                Text("Object").tag(RollPitchYaw.Target.object)
                Text("World").tag(RollPitchYaw.Target.world)
            }
            switch target {
            case .object:
                MatrixEditor(.constant(rollPitchYaw.matrix3x3))
            case .world:
                MatrixEditor(.constant(rollPitchYaw.worldMatrix3x3))
            }
        }
    }
}

#Preview {
    @Previewable @State var rollPitchYaw = RollPitchYaw()
    Form {
        RollPitchYawEditor($rollPitchYaw)
    }
}
