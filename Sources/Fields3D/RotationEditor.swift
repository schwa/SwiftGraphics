import CoreGraphicsSupport
import Foundation
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

public struct RotationEditor: View {
    @Binding
    var rotation: Rotation

    @State
    private var mode: Rotation.Storage.Base

    @State
    private var editedRotation: Rotation

    public init(_ rotation: Binding<Rotation>) {
        self._rotation = rotation
        self.mode = rotation.wrappedValue.storage.base
        self.editedRotation = rotation.wrappedValue
    }

    public var body: some View {
        Group {
            Picker("Mode", selection: $mode) {
                Text("Quaternion").tag(Rotation.Storage.Base.quaternion)
                Text("Roll Pitch Yaw").tag(Rotation.Storage.Base.rollPitchYaw)
            }

            switch editedRotation.storage {
            case .quaternion:
                QuaternionEditor($editedRotation.quaternion)
            case .rollPitchYaw:
                RollPitchYawEditor($editedRotation.rollPitchYaw)
            }
        }
        .onChange(of: mode) {
            editedRotation = rotation.converted(to: mode)
        }
        .onChange(of: rotation) {
            editedRotation = rotation.converted(to: mode)
        }
    }
}

extension Rotation {
    func converted(to base: Rotation.Storage.Base) -> Rotation {
        switch base {
        case .quaternion:
            Rotation(quaternion: quaternion)
        case .rollPitchYaw:
            Rotation(rollPitchYaw: rollPitchYaw)
        }
    }
}
extension Rotation.Storage {
    enum Base {
        case quaternion
        case rollPitchYaw
    }

    var base: Base {
        switch self {
        case .quaternion:
            .quaternion
        case .rollPitchYaw:
            .rollPitchYaw
        }
    }
}

#Preview {
    @Previewable @State var rotation = Rotation.identity
    RotationEditor($rotation)
}
