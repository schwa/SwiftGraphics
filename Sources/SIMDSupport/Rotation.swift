import simd
import SwiftUI

public struct Rotation {
    public enum Storage: Sendable, Equatable {
        case quaternion(simd_quatf)
        case rollPitchYaw(RollPitchYaw)
    }

    public var storage: Storage

    public static let identity = Self.quaternion(.identity)
}

extension Rotation: Sendable {
}

public extension Rotation {
    var matrix: simd_float4x4 {
        switch storage {
        case .quaternion(let quaternion):
            return simd_float4x4(quaternion)
        case .rollPitchYaw(let rollPitchYaw):
            return .init(rollPitchYaw.matrix3x3)
        }
    }
}

extension Rotation: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.quaternion == rhs.quaternion
    }
}

public extension Rotation {
    init(quaternion: simd_quatf) {
        storage = .quaternion(quaternion)
    }

    init(rollPitchYaw: RollPitchYaw) {
        storage = .rollPitchYaw(rollPitchYaw)
    }

    static func quaternion(_ quaternion: simd_quatf) -> Self {
        .init(quaternion: quaternion)
    }

    static func rollPitchYaw(_ rollPitchYaw: RollPitchYaw) -> Self {
        .init(rollPitchYaw: rollPitchYaw)
    }
}

public extension Rotation {
    var quaternion: simd_quatf {
        get {
            switch storage {
            case .quaternion(let quaternion):
                return quaternion
            case .rollPitchYaw(let rollPitchYaw):
                return rollPitchYaw.quaternion
            }
        }
        set {
            storage = .quaternion(newValue)
        }
    }

    var rollPitchYaw: RollPitchYaw {
        get {
            switch storage {
            case .quaternion(let quaternion):
                return RollPitchYaw(target: .object, quaternion: quaternion)
            case .rollPitchYaw(let rollPitchYaw):
                return rollPitchYaw
            }
        }
        set {
            storage = .rollPitchYaw(newValue)
        }
    }
}

extension Rotation: Hashable {
    public func hash(into hasher: inout Hasher) {
        matrix.altHash(into: &hasher)
    }
}

public extension Rotation {
    init(angle: Angle, axis: SIMD3<Float>) {
        self = .quaternion(.init(angle: angle, axis: axis))
    }
}
