import CoreGraphicsSupport
import Everything
import simd
import SwiftUI

// TODO: Move/Rename
public struct Rotation: Hashable {
    public var pitch: Angle
    public var yaw: Angle
    public var roll: Angle

    public init(pitch: Angle = .zero, yaw: Angle = .zero, roll: Angle = .zero) {
        self.pitch = pitch
        self.yaw = yaw
        self.roll = roll
    }

    static let zero = Rotation(pitch: .zero, yaw: .zero, roll: .zero)
}

public extension Rotation {
    var quaternion: simd_quatf {
        let pitch = simd_quatf(angle: Float(pitch.radians), axis: [1, 0, 0])
        let yaw = simd_quatf(angle: Float(yaw.radians), axis: [0, 1, 0])
        let roll = simd_quatf(angle: Float(roll.radians), axis: [0, 0, 1])
        return yaw * pitch * roll // TODO: Order matters
    }

    var matrix: simd_float4x4 {
        simd_float4x4(quaternion)
    }
}

public extension Rotation {
    static func + (lhs: Rotation, rhs: Rotation) -> Rotation {
        Rotation(pitch: lhs.pitch + rhs.pitch, yaw: lhs.yaw + rhs.yaw, roll: lhs.roll + rhs.roll)
    }
}

public struct BallRotationModifier: ViewModifier {
    @Binding
    var rotation: Rotation

    let pitchLimit: ClosedRange<Angle>
    let yawLimit: ClosedRange<Angle>
    let interactionScale: CGVector
    let coordinateSpace = ObjectIdentifier(Self.self)

    public static let defaultInteractionScale = CGVector(1 / .pi, 1 / .pi)

    @State
    var initialGestureRotation: Rotation?

    @State
    var cameraMoved = false

    public init(rotation: Binding<Rotation>, pitchLimit: ClosedRange<Angle> = .degrees(-90) ... .degrees(90), yawLimit: ClosedRange<Angle> = .degrees(-.infinity) ... .degrees(.infinity), interactionScale: CGVector = Self.defaultInteractionScale) {
        _rotation = rotation
        self.pitchLimit = pitchLimit
        self.yawLimit = yawLimit
        self.interactionScale = interactionScale
    }

    public func body(content: Content) -> some View {
        content
            .coordinateSpace(name: coordinateSpace)
            .simultaneousGesture(dragGesture())
            .onChange(of: pitchLimit) {
                rotation.pitch = clamp(rotation.pitch, in: pitchLimit)
            }
            .onChange(of: yawLimit) {
                rotation.yaw = clamp(rotation.yaw, in: yawLimit)
            }
    }

    func dragGesture() -> some Gesture {
        DragGesture(coordinateSpace: .named(coordinateSpace))
            .onChanged { value in
                rotation = convert(translation: CGVector(value.translation))
            }
            .onEnded { value in
                withAnimation(.easeOut) {
                    rotation = convert(translation: CGVector(value.predictedEndTranslation))
                }
                initialGestureRotation = nil
                cameraMoved = false
            }
    }

    func convert(translation: CGVector) -> Rotation {
        if initialGestureRotation == nil {
            initialGestureRotation = rotation
        }
        guard let initialGestureRotation else {
            fatalError()
        }
        var rotation = initialGestureRotation
        rotation.pitch = clamp(rotation.pitch + .degrees(translation.dy * interactionScale.dy), in: pitchLimit)
        rotation.yaw = clamp(rotation.yaw + .degrees(translation.dx * interactionScale.dx), in: yawLimit)
        return rotation
    }
}

public extension View {
    func ballRotation(_ rotation: Binding<Rotation>, pitchLimit: ClosedRange<Angle> = .degrees(-90) ... .degrees(90), yawLimit: ClosedRange<Angle> = .degrees(-.infinity) ... .degrees(.infinity), interactionScale: CGVector = BallRotationModifier.defaultInteractionScale) -> some View {
        modifier(BallRotationModifier(rotation: rotation, pitchLimit: pitchLimit, yawLimit: yawLimit, interactionScale: interactionScale))
    }
}

func abs(_ value: Angle) -> Angle {
    .radians(Swift.abs(value.radians))
}
