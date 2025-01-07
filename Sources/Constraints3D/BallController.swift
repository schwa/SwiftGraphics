import simd
import SIMDSupport
import SwiftUI

public struct NewBallControllerViewModifier: ViewModifier {
    private var constraint: NewBallConstraint

    @State
    private var pitch: Angle = .zero

    @State
    private var yaw: Angle = .zero

    @Binding
    var transform: simd_float4x4

    var debug: Bool = false

    var pitchRange: ClosedRange<Angle> = .degrees(-90) ... .degrees(90)
    var yawRange: ClosedRange<Angle> = .degrees(0) ... .degrees(360)

    public init(constraint: NewBallConstraint, transform: Binding<simd_float4x4>, debug: Bool = false) {
        self.constraint = constraint
        self._transform = transform
        self.debug = debug
        // TODO: compute pitch yaw from transform
    }

    public func body(content: Content) -> some View {
        content
            .draggableParameter($pitch.degrees, axis: .vertical, range: pitchRange.degrees, scale: 0.1, behavior: .clamping)
            .draggableParameter($yaw.degrees, axis: .horizontal, range: yawRange.degrees, scale: 0.1, behavior: .wrapping)
            .onChange(of: [pitch, yaw], initial: true) {
                transform = constraint.transform(for: RollPitchYaw(pitch: pitch, yaw: yaw)).matrix
            }
            .onChange(of: constraint) {
                transform = constraint.transform(for: RollPitchYaw(pitch: pitch, yaw: yaw)).matrix
            }
//            .onTapGesture {
//                if debug {
//                    pitch = .zero
//                    yaw = .zero
//                }
//            }
            .overlay(alignment: .bottom) {
                if debug {
                    HStack {
                        LabeledContent("pitch") {
                            TextField("pitch", value: $pitch.degrees, format: .number.precision(.fractionLength(0...2)))
                        }
                        LabeledContent("yaw") {
                            TextField("yaw", value: $yaw.degrees, format: .number.precision(.fractionLength(0...2)))
                        }
                        Button("Reset") {
                            pitch = .zero
                            yaw = .zero
                        }
                    }
                    .frame(width: 320)
                    .controlSize(.small)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding()
                }
            }
    }
}

public extension NewBallControllerViewModifier {
    init(constraint: NewBallConstraint, transform: Binding<Transform>, debug: Bool = false) {
        self.init(constraint: constraint, transform: Binding(get: { transform.wrappedValue.matrix }, set: { transform.wrappedValue = Transform($0) }), debug: debug)
    }
}

// MARK: -

public struct NewBallConstraint: Equatable {
    public var target: SIMD3<Float>
    public var radius: Float

    public init(target: SIMD3<Float> = .zero, radius: Float) {
        self.target = target
        self.radius = radius
    }

    public func transform(for rotation: RollPitchYaw) -> Transform {
        Transform(simd_float4x4(translate: [0, 0, radius]) * rotation.toMatrix4x4(order: .rollPitchYaw))
    }
}
