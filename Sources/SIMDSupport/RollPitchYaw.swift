import simd
import SwiftUI

public struct RollPitchYaw: Hashable {
    public var roll: Angle
    public var pitch: Angle
    public var yaw: Angle

    public init(roll: Angle = .zero, pitch: Angle = .zero, yaw: Angle = .zero) {
        self.roll = roll
        self.pitch = pitch
        self.yaw = yaw
    }

    public static let zero = Self(roll: .zero, pitch: .zero, yaw: .zero)
}

public extension RollPitchYaw {
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

public extension RollPitchYaw {
    static func + (lhs: RollPitchYaw, rhs: RollPitchYaw) -> RollPitchYaw {
        RollPitchYaw(roll: lhs.roll + rhs.roll, pitch: lhs.pitch + rhs.pitch, yaw: lhs.yaw + rhs.yaw)
    }
}
