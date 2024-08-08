import simd
import SIMDSupport
import SwiftUI

public struct NewBallControllerViewModifier: ViewModifier {
    @State
    private var constraint: NewBallConstraint

    @Binding
    var transform: Transform

    var pitchRange: ClosedRange<Angle> = .degrees(-90) ... .degrees(90)
    var yawRange: ClosedRange<Angle> = .degrees(0) ... .degrees(360)

    public init(constraint: NewBallConstraint, transform: Binding<Transform>) {
        self.constraint = constraint
        self._transform = transform
    }

    public func body(content: Content) -> some View {
        content
        .draggableParameter($constraint.pitch.degrees, axis: .vertical, range: pitchRange.degrees, scale: 0.1, behavior: .clamping)
        .draggableParameter($constraint.yaw.degrees, axis: .horizontal, range: yawRange.degrees, scale: 0.1, behavior: .wrapping)
        .onChange(of: constraint.transform, initial: true) {
            transform = constraint.transform
        }
    }
}

extension ClosedRange where Bound == Angle {
    var degrees: ClosedRange<Double> {
        lowerBound.degrees ... upperBound.degrees
    }
}

// MARK: -

public struct NewBallConstraint: Equatable {
    public var transform: Transform {
        Transform((RollPitchYaw(pitch: pitch, yaw: yaw).toMatrix4x4(order: .rollPitchYaw) * simd_float4x4(translate: [0, 0, radius])))
   }

    public var target: SIMD3<Float>
    public var radius: Float
    public var pitch: Angle
    public var yaw: Angle

    public init(target: SIMD3<Float> = .zero, pitch: Angle = .zero, yaw: Angle = .zero, radius: Float) {
        self.target = target
        self.radius = radius
        self.pitch = pitch
        self.yaw = yaw
    }
}
