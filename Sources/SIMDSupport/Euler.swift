import simd

public struct Euler<Scalar> where Scalar: SIMDScalar & BinaryFloatingPoint {
    public var roll: Scalar
    public var pitch: Scalar
    public var yaw: Scalar

    public init(roll: Scalar = .zero, pitch: Scalar = .zero, yaw: Scalar = .zero) {
        self.roll = roll
        self.pitch = pitch
        self.yaw = yaw
    }
}

extension Euler: Hashable {
}

public extension Euler {
    static var identity: Self {
        Euler(roll: .zero, pitch: .zero, yaw: .zero)
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        .init(roll: lhs.roll + rhs.roll, pitch: lhs.pitch + rhs.pitch, yaw: lhs.yaw + rhs.yaw)
    }

    init(_ other: Euler<some Any>) {
        self = .init(other.scalars.map { Scalar($0) })
    }
}

extension Euler {
    init(_ scalars: [Scalar]) {
        self = .init(roll: scalars[0], pitch: scalars[1], yaw: scalars[2])
    }

    var scalars: [Scalar] {
        // Is this order actually correct (see simd_quat(angle:axis:)
        [roll, pitch, yaw]
    }
}

// MARK: Euler<Double> <-> simd_quatd

public extension Euler where Scalar == Double {
    init(_ quaternion: simd_quatd) {
        let q = quaternion.vector

        let siny_cosp = 2 * (q.w * q.z + q.x * q.y)
        let cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z)
        let yaw = atan2(siny_cosp, cosy_cosp)

        let sinp = 2 * (q.w * q.y - q.z * q.x)
        let pitch: Double = if abs(sinp) >= 1 {
            copysign(.pi / 2, sinp)
        }
        else {
            asin(sinp)
        }

        let sinr_cosp = 2 * (q.w * q.x + q.y * q.z)
        let cosr_cosp = 1 - 2 * (q.x * q.x + q.y * q.y)
        let roll = atan2(sinr_cosp, cosr_cosp)

        self = Euler(roll: roll, pitch: pitch, yaw: yaw)
    }
}

public extension simd_quatd {
    init(_ euler: Euler<Double>) {
        let roll2: Double = euler.roll / 2
        let pitch2: Double = euler.pitch / 2
        let yaw2: Double = euler.yaw / 2
        let ix: Double = sin(roll2) * cos(pitch2) * cos(yaw2) - cos(roll2) * sin(pitch2) * sin(yaw2)
        let iy: Double = cos(roll2) * sin(pitch2) * cos(yaw2) + sin(roll2) * cos(pitch2) * sin(yaw2)
        let iz: Double = cos(roll2) * cos(pitch2) * sin(yaw2) - sin(roll2) * sin(pitch2) * cos(yaw2)
        let r: Double = cos(roll2) * cos(pitch2) * cos(yaw2) + sin(roll2) * sin(pitch2) * sin(yaw2)
        self = .init(ix: ix, iy: iy, iz: iz, r: r)
    }
}

// MARK: Euler<Float> <-> simd_quatf

public extension Euler where Scalar == Float {
    init(_ quaternion: simd_quatf) {
        let quaternion = simd_quatd(quaternion)
        let euler = Euler<Double>(quaternion)
        self = .init(euler)
    }
}

public extension simd_quatf {
    init(_ euler: Euler<Float>) {
        let euler = Euler<Double>(euler)
        self = simd_quatf(simd_quatd(euler))
    }
}
