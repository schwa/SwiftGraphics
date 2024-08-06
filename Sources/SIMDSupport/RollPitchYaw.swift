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

//    // Helper function to create a rotation matrix from RollPitchYaw
//    func createRotationMatrix(from orientation: RollPitchYaw) -> simd_float4x4 {
//        let cx = cos(Float(orientation.pitch.radians))
//        let sx = sin(Float(orientation.pitch.radians))
//        let cy = cos(Float(orientation.yaw.radians))
//        let sy = sin(Float(orientation.yaw.radians))
//        let cz = cos(Float(orientation.roll.radians))
//        let sz = sin(Float(orientation.roll.radians))
//
//        return simd_float4x4(
//            SIMD4<Float>(cy * cz, cx * sz + sx * sy * cz, sx * sz - cx * sy * cz, 0),
//            SIMD4<Float>(-cy * sz, cx * cz - sx * sy * sz, sx * cz + cx * sy * sz, 0),
//            SIMD4<Float>(sy, -sx * cy, cx * cy, 0),
//            SIMD4<Float>(0, 0, 0, 1)
//        )
//    }


public extension XYZRotation {
    enum Order: CaseIterable {
        case xyz
        case xzy
        case yxz
        case yzx
        case zxy
        case zyx
    }

    func toMatrix3x3(order: Order) -> simd_float3x3 {
        let cx = Float(cos(x.angle))
        let sx = Float(sin(x.angle))
        let cy = Float(cos(y.angle))
        let sy = Float(sin(y.angle))
        let cz = Float(cos(z.angle))
        let sz = Float(sin(z.angle))

        switch order {
        case .xyz:
            return simd_float3x3(
                simd_float3(cy * cz, cy * sz, -sy),
                simd_float3(sx * sy * cz - cx * sz, sx * sy * sz + cx * cz, sx * cy),
                simd_float3(cx * sy * cz + sx * sz, cx * sy * sz - sx * cz, cx * cy)
            )
        case .xzy:
            return simd_float3x3(
                simd_float3(cy * cz, sz, -sy * cz),
                simd_float3(-cy * sz * cx + sy * sx, cx * cz, sy * sz * cx + cy * sx),
                simd_float3(cy * sz * sx + sy * cx, -sx * cz, -sy * sz * sx + cy * cx)
            )
        case .yxz:
            return simd_float3x3(
                simd_float3(cy * cz + sy * sx * sz, cy * sz - sy * sx * cz, -sy * cx),
                simd_float3(cx * sz, cx * cz, sx),
                simd_float3(sy * cz - cy * sx * sz, sy * sz + cy * sx * cz, cy * cx)
            )
        case .yzx:
            return simd_float3x3(
                simd_float3(cy * cz, sx * sy - cx * cy * sz, cx * sy + sx * cy * sz),
                simd_float3(sz, cx * cz, -sx * cz),
                simd_float3(-sy * cz, sx * cy + cx * sy * sz, cx * cy - sx * sy * sz)
            )
        case .zxy:
            return simd_float3x3(
                simd_float3(cy * cz, sz, -sy * cz),
                simd_float3(-cx * cy * sz + sx * sy, cx * cz, cx * sy * sz + sx * cy),
                simd_float3(sx * cy * sz + cx * sy, -sx * cz, -sx * sy * sz + cx * cy)
            )
        case .zyx:
            return simd_float3x3(
                simd_float3(cy * cz, cx * sz + sx * sy * cz, sx * sz - cx * sy * cz),
                simd_float3(-cy * sz, cx * cz - sx * sy * sz, sx * cz + cx * sy * sz),
                simd_float3(sy, -sx * cy, cx * cy)
            )
        }
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
