import simd
import SIMDSupport
import SwiftFields
import SwiftFormats
import SwiftUI

public struct NewBallControllerViewModifier: ViewModifier {
    @State
    private var constraint: NewBallConstraint

    @Binding
    var transform: simd_float4x4

    var debug: Bool = false

    public init(constraint: NewBallConstraint, transform: Binding<simd_float4x4>, debug: Bool = false) {
        self._constraint = State(initialValue: constraint)
        self._transform = transform
        self.debug = debug
        // TODO: compute pitch yaw from transform
    }

    public func body(content: Content) -> some View {
        content
            .draggableParameter($constraint.pitch.degrees, axis: .vertical, range: constraint.pitchRange.degrees, scale: 0.1, behavior: .clamping)
            .draggableParameter($constraint.yaw.degrees, axis: .horizontal, range: constraint.yawRange.degrees, scale: 0.1, behavior: .wrapping)
            .onChange(of: constraint, initial: true) {
                transform = constraint.transform
            }
            .overlay(alignment: .bottom) {
                if debug {
                    NewBallConstraintEditor(constraint: $constraint)
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
    public var pitch: Angle = .zero
    public var yaw: Angle = .zero
    public var towards: Bool = true
    public var pitchRange: ClosedRange<Angle> = .degrees(-90) ... .degrees(90)
    public var yawRange: ClosedRange<Angle> = .degrees(0) ... .degrees(360)

    public init(target: SIMD3<Float> = .zero, radius: Float) {
        self.target = target
        self.radius = radius
    }

    public var transform: simd_float4x4 {
        // Convert SwiftUI Angles to radians:
        let rotation = simd_quatf(angle: Float(yaw.radians), axis: [0, 1, 0]) * simd_quatf(angle: Float(pitch.radians), axis: [1, 0, 0])
        let localPos = SIMD4<Float>(0, 0, radius, 1)
        let rotatedOffset = simd_float4x4(rotation) * localPos
        let other = target + rotatedOffset.xyz
        if towards {
            return look(at: target, from: other, up: [0, 1, 0])
        } else {
            return look(at: other, from: target, up: [0, 1, 0])
        }
    }
}

// MARK: -

struct NewBallConstraintEditor: View {
    @Binding
    var constraint: NewBallConstraint

    var body: some View {
        HStack(alignment: .top) {
            LabeledContent("Target") {
                VectorEditor($constraint.target)
            }
            VStack {
                LabeledContent("pitch") {
                    HStack {
                        TextField("pitch", value: $constraint.pitch.degrees, format: .number.precision(.fractionLength(0...2)))
                        Slider(value: $constraint.pitch.degrees, in: constraint.pitchRange.degrees)
                    }
                }
                LabeledContent("yaw") {
                    HStack {
                        TextField("yaw", value: $constraint.yaw.degrees, format: .number.precision(.fractionLength(0...2)))
                        Slider(value: $constraint.yaw.degrees, in: constraint.yawRange.degrees)
                    }
                }
                LabeledContent("Radius") {
                    HStack {
                        TextField("radius", value: $constraint.radius, format: .number.precision(.fractionLength(0...2)))
                        Slider(value: $constraint.radius, in: 0...10)
                    }
                }
            }
            //            LabeledContent("Transform") {
            //                Text("\(constraint.transform, format: .matrix.scalarStyle(.number.precision(.fractionLength(0...2))))")
            MatrixView(constraint.transform)
            //            }

            Menu("Options", systemImage: "gear") {
                Button("Reset") {
                    constraint.pitch = .zero
                    constraint.yaw = .zero
                }
                Toggle("Towards", isOn: $constraint.towards)
            }
            .labelsHidden()
        }
    }
}
