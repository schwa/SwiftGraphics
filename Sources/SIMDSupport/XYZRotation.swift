import simd
import SwiftUI

public typealias RollPitchYaw = XYZRotation

// https://www.redcrab-software.com/en/Calculator/3x3/Matrix/Rotation-Matrix
// https://www.wolframalpha.com/input?i=roll+pitch+yaw
// https://www.wikidoc.org/index.php/Tait-Bryan_rotations

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
    enum Order: CaseIterable, Sendable {
        case xyz
        case xzy
        case yxz
        case yzx
        case zxy
        case zyx

        // zyx order ensures correct matrix multiplication for roll (x), pitch (y), yaw (z)
        public static let rollPitchYaw = Self.zyx
    }

    func toMatrix3x3(order: Order) -> simd_float3x3 {
        let x = simd_float3x3(rotationAngle: x, axis: [1, 0, 0])
        let y = simd_float3x3(rotationAngle: y, axis: [0, 1, 0])
        let z = simd_float3x3(rotationAngle: z, axis: [0, 0, 1])
        switch order {
        case .xyz:
            return z * y * x
        case .xzy:
            return y * z * x
        case .yxz:
            return z * x * y
        case .yzx:
            return x * z * y
        case .zxy:
            return y * x * z
        case .zyx:
            return x * y * z
        }
    }

    func toMatrix4x4(order: Order) -> simd_float4x4 {
        .init(toMatrix3x3(order: order))
    }

    func toQuaternion(order: Order) -> simd_quatf {
        simd_quatf(toMatrix4x4(order: order))
    }
}

public extension XYZRotation {
    // THis only works for zyx order right now
    init(target: Target = .object, matrix: simd_float3x3, order: Order) {
        assert(order == .zyx)
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
}

public extension XYZRotation {
    static let zero = XYZRotation()

    static func + (lhs: XYZRotation, rhs: XYZRotation) -> XYZRotation {
        XYZRotation(roll: lhs.roll + rhs.roll, pitch: lhs.pitch + rhs.pitch, yaw: lhs.yaw + rhs.yaw)
    }
}

public extension XYZRotation {
    init(target: Target = .object, quaternion: simd_quatf, order: Order) {
        let matrix4x4 = simd_float4x4(quaternion)
        let matrix3x3 = simd_float3x3(matrix4x4)
        self.init(target: target, matrix: matrix3x3, order: order)
    }
}

extension XYZRotation: CustomStringConvertible {
    public var description: String {
        XYZRotationFormatStyle().format(self)
    }
}

public struct XYZRotationFormatStyle: FormatStyle {
    public typealias FormatInput = XYZRotation
    public typealias FormatOutput = String

    public func format(_ value: XYZRotation) -> String {
        "roll: \(value.roll.degrees.formatted())°, pitch: \(value.pitch.degrees.formatted())°, yaw: \(value.yaw.degrees.formatted())°"
    }
}

public extension FormatStyle where Self == XYZRotationFormatStyle {
    static var XYZRotation: Self {
        Self()
    }
}
