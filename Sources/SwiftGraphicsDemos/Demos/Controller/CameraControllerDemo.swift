import Widgets3D
import CoreGraphicsSupport
import simd
import SIMDSupport
import SwiftUI

struct CameraControllerDemo: DemoView {
    @State
    var transform: Transform = .identity

    var body: some View {
        ZStack {
            Color.white
            Circle().fill(Color.orange).frame(width: 10, height: 10).offset(CGPoint(transform.translation.xz) * 25)
        }
        .modifier(FirstPerson3DGameControllerViewModifier(transform: $transform))

        .inspector {
            GameControllerInspector()
        }
    }
}
