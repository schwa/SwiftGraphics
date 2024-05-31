import simd
import SwiftUI

public struct RollPitchYaw: Sendable, Hashable {
//    enum Order {
//        case rollPitchYaw
//        case yawPitchRoll
//    }

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
    var matrix: simd_float4x4 {
        simd_float4x4(quaternion)
    }
}

public extension RollPitchYaw {
    static func + (lhs: RollPitchYaw, rhs: RollPitchYaw) -> RollPitchYaw {
        RollPitchYaw(roll: lhs.roll + rhs.roll, pitch: lhs.pitch + rhs.pitch, yaw: lhs.yaw + rhs.yaw)
    }
}

public extension RollPitchYaw {
    init(quaternion: simd_quatf) {
        // TODO: Not symetrical with .quaternion_factor
        let q = quaternion.vector

        let siny_cosp = 2 * (q.w * q.z + q.x * q.y)
        let cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z)
        let yaw = atan2(siny_cosp, cosy_cosp)

        let sinp = 2 * (q.w * q.y - q.z * q.x)
        let pitch: Float = if abs(sinp) >= 1 {
            copysign(.pi / 2, sinp)
        }
        else {
            asin(sinp)
        }

        let sinr_cosp = 2 * (q.w * q.x + q.y * q.z)
        let cosr_cosp = 1 - 2 * (q.x * q.x + q.y * q.y)
        let roll = atan2(sinr_cosp, cosr_cosp)

        self = .init(roll: .radians(Double(roll)), pitch: .radians(Double(pitch)), yaw: .radians(Double(yaw)))
    }

    var quaternion: simd_quatf {
        quaternion_factor
    }

    // TODO: This has a different result from...
    var quaternion_factor: simd_quatf {
        let roll = simd_quatf(angle: Float(roll.radians), axis: [0, 0, 1])
        let pitch = simd_quatf(angle: Float(pitch.radians), axis: [1, 0, 0])
        let yaw = simd_quatf(angle: Float(yaw.radians), axis: [0, 1, 0])
        return yaw * pitch * roll // TODO: Order matters
    }

    // TODO:  ... this… which is a problem for init(quat:)
    var quaternion_direct: simd_quatf {
        let roll2 = roll.radians / 2
        let pitch2 = pitch.radians / 2
        let yaw2 = yaw.radians / 2
        let ix: Double = sin(roll2) * cos(pitch2) * cos(yaw2) - cos(roll2) * sin(pitch2) * sin(yaw2)
        let iy: Double = cos(roll2) * sin(pitch2) * cos(yaw2) + sin(roll2) * cos(pitch2) * sin(yaw2)
        let iz: Double = cos(roll2) * cos(pitch2) * sin(yaw2) - sin(roll2) * sin(pitch2) * cos(yaw2)
        let r: Double = cos(roll2) * cos(pitch2) * cos(yaw2) + sin(roll2) * sin(pitch2) * sin(yaw2)
        return simd_quatf(ix: Float(ix), iy: Float(iy), iz: Float(iz), r: Float(r))
    }
}

extension RollPitchYaw: Codable {
    enum CodingKeys: CodingKey {
        case roll
        case pitch
        case yaw
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        roll = try .degrees(container.decodeIfPresent(Double.self, forKey: .roll) ?? 0)
        pitch = try .degrees(container.decodeIfPresent(Double.self, forKey: .pitch) ?? 0)
        yaw = try .degrees(container.decodeIfPresent(Double.self, forKey: .yaw) ?? 0)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(roll.degrees, forKey: .roll)
        try container.encode(pitch.degrees, forKey: .pitch)
        try container.encode(yaw.degrees, forKey: .yaw)
    }
}

extension RollPitchYaw: CustomStringConvertible {
    public var description: String {
        RollPitchYawFormatStyle().format(self)
    }
}

public struct RollPitchYawFormatStyle: FormatStyle {
    public typealias FormatInput = RollPitchYaw

    public typealias FormatOutput = String

    public func format(_ value: RollPitchYaw) -> String {
        "roll: \(value.roll.degrees.formatted())°, pitch: \(value.pitch.degrees.formatted())°, yaw: \(value.yaw.degrees.formatted())°"
    }
}

public extension FormatStyle where Self == RollPitchYawFormatStyle {
    static var rollPitchYaw: Self {
        Self()
    }
}
