import CoreGraphicsSupport
import simd
import SwiftUI

// TODO: Move/Rename
struct RollPitchYaw: Hashable {
    var roll: Angle
    var pitch: Angle
    var yaw: Angle

    init(roll: Angle = .zero, pitch: Angle = .zero, yaw: Angle = .zero) {
        self.roll = roll
        self.pitch = pitch
        self.yaw = yaw
    }

    static let zero = Self(roll: .zero, pitch: .zero, yaw: .zero)
}

extension RollPitchYaw {
    var quaternion: simd_quatf {
        let roll = simd_quatf(angle: Float(roll.radians), axis: [0, 0, 1])
        let pitch = simd_quatf(angle: Float(pitch.radians), axis: [1, 0, 0])
        let yaw = simd_quatf(angle: Float(yaw.radians), axis: [0, 1, 0])
        return yaw * pitch * roll // TODO: Order matters
    }

    var matrix: simd_float4x4 {
        simd_float4x4(quaternion)
    }
}

extension RollPitchYaw {
    static func + (lhs: RollPitchYaw, rhs: RollPitchYaw) -> RollPitchYaw {
        RollPitchYaw(roll: lhs.roll + rhs.roll, pitch: lhs.pitch + rhs.pitch, yaw: lhs.yaw + rhs.yaw)
    }
}

struct BallRotationModifier: ViewModifier {
    @Binding
    var rollPitchYaw: RollPitchYaw

    let pitchLimit: ClosedRange<Angle>
    let yawLimit: ClosedRange<Angle>
    let interactionScale: CGVector
    let coordinateSpace = ObjectIdentifier(Self.self)

    static let defaultInteractionScale = CGVector(1 / .pi, 1 / .pi)

    @State
    var initialGestureRollPitchYaw: RollPitchYaw?

    @State
    var cameraMoved = false

    init(rollPitchYaw: Binding<RollPitchYaw>, pitchLimit: ClosedRange<Angle> = .degrees(-90) ... .degrees(90), yawLimit: ClosedRange<Angle> = .degrees(-.infinity) ... .degrees(.infinity), interactionScale: CGVector = Self.defaultInteractionScale) {
        _rollPitchYaw = rollPitchYaw
        self.pitchLimit = pitchLimit
        self.yawLimit = yawLimit
        self.interactionScale = interactionScale
    }

    func body(content: Content) -> some View {
        content
            .coordinateSpace(name: coordinateSpace)
            .simultaneousGesture(dragGesture())
            .onChange(of: pitchLimit) {
                rollPitchYaw.pitch = clamp(rollPitchYaw.pitch, in: pitchLimit)
            }
            .onChange(of: yawLimit) {
                rollPitchYaw.yaw = clamp(rollPitchYaw.yaw, in: yawLimit)
            }
    }

    func dragGesture() -> some Gesture {
        DragGesture(coordinateSpace: .named(coordinateSpace))
            .onChanged { value in
                rollPitchYaw = convert(translation: CGVector(value.translation))
            }
            .onEnded { value in
                withAnimation(.easeOut) {
                    rollPitchYaw = convert(translation: CGVector(value.predictedEndTranslation))
                }
                initialGestureRollPitchYaw = nil
                cameraMoved = false
            }
    }

    func convert(translation: CGVector) -> RollPitchYaw {
        if initialGestureRollPitchYaw == nil {
            initialGestureRollPitchYaw = rollPitchYaw
        }
        guard let initialGestureRollPitchYaw else {
            unreachable()
        }
        var rollPitchYaw = initialGestureRollPitchYaw
        rollPitchYaw.pitch = clamp(rollPitchYaw.pitch + .degrees(translation.dy * interactionScale.dy), in: pitchLimit)
        rollPitchYaw.yaw = clamp(rollPitchYaw.yaw + .degrees(translation.dx * interactionScale.dx), in: yawLimit)
        return rollPitchYaw
    }
}

extension View {
    func ballRotation(_ rollPitchYaw: Binding<RollPitchYaw>, pitchLimit: ClosedRange<Angle> = .degrees(-90) ... .degrees(90), yawLimit: ClosedRange<Angle> = .degrees(-.infinity) ... .degrees(.infinity), interactionScale: CGVector = BallRotationModifier.defaultInteractionScale) -> some View {
        modifier(BallRotationModifier(rollPitchYaw: rollPitchYaw, pitchLimit: pitchLimit, yawLimit: yawLimit, interactionScale: interactionScale))
    }
}
