import simd
import SwiftUI

public typealias RollPitchYaw = XYZRotation

public struct XYZRotation: Sendable, Equatable {
    public enum Target: Sendable {
        case object
        case world
    }

    public var x: Angle
    public var y: Angle
    public var z: Angle

    public init() {
        x = .zero
        y = .zero
        z = .zero
    }

    public init(x: Angle = .zero, y: Angle = .zero, z: Angle = .zero) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public extension XYZRotation {
    var roll: Angle {
        get {
            z
        }
        set {
            z = newValue
        }
    }
    var pitch: Angle {
        get {
            x
        }
        set {
            x = newValue
        }
    }
    var yaw: Angle {
        get {
            y
        }
        set {
            y = newValue
        }
    }

    init(roll: Angle = .zero, pitch: Angle = .zero, yaw: Angle = .zero) {
        self.init()
        self.roll = roll
        self.pitch = pitch
        self.yaw = yaw
    }
}

public extension XYZRotation {
    init(target: Target = .object, matrix: simd_float3x3) {
        // https://web.archive.org/web/20220428033032/
        // http://planning.cs.uiuc.edu/node103.html
        let x = -atan2(matrix[2][1], matrix[2][2])
        let y = -atan2(-matrix[2][0], sqrt(matrix[2][1] * matrix[2][1] + matrix[2][2] * matrix[2][2]))
        let z = -atan2(matrix[1][0], matrix[0][0])
        switch target {
        case .object:
            self.init(x: .radians(Double(x)), y: .radians(Double(y)), z: .radians(Double(z)))
        case .world:
            self.init(x: .radians(Double(-x)), y: .radians(Double(-y)), z: .radians(Double(-z)))
        }
    }

    var matrix3x3: simd_float3x3 {
        let x = simd_float3x3(rotationAngle: x, axis: [1, 0, 0])
        let y = simd_float3x3(rotationAngle: y, axis: [0, 1, 0])
        let z = simd_float3x3(rotationAngle: z, axis: [0, 0, 1])
        return x * y * z
    }

    var worldMatrix3x3: simd_float3x3 {
        let x = simd_float3x3(rotationAngle: -x, axis: [-1, 0, 0])
        let y = simd_float3x3(rotationAngle: -y, axis: [0, -1, 0])
        let z = simd_float3x3(rotationAngle: -z, axis: [0, 0, -1])
        return x * y * z
    }
}

public extension XYZRotation {
    var matrix4x4: simd_float4x4 {
        .init(matrix3x3)
    }
    var worldMatrix4x4: simd_float4x4 {
        .init(worldMatrix3x3)
    }
}

public extension XYZRotation {
    static let zero = XYZRotation()

    static func + (lhs: XYZRotation, rhs: XYZRotation) -> XYZRotation {
        XYZRotation(roll: lhs.roll + rhs.roll, pitch: lhs.pitch + rhs.pitch, yaw: lhs.yaw + rhs.yaw)
    }
}

public extension XYZRotation {
    init(target: Target = .object, quaternion: simd_quatf) {
        let matrix4x4 = simd_float4x4(quaternion)
        let matrix3x3 = simd_float3x3(matrix4x4)
        self.init(target: target, matrix: matrix3x3)
    }

    var quaternion: simd_quatf {
        simd_quatf(matrix4x4)
    }

    var worldQuaternion: simd_quatf {
        simd_quatf(worldMatrix4x4)
    }
}

extension RollPitchYaw: CustomStringConvertible {
    public var description: String {
        RollPitchYawFormatStyle().format(self)
    }
}

public struct RollPitchYawFormatStyle: FormatStyle {
    public typealias FormatInput = XYZRotation
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
