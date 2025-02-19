import simd
import SwiftUI

public struct Rotation {
    public enum Storage: Sendable, Equatable {
        case quaternion(simd_quatf)
        case rollPitchYaw(RollPitchYaw)
    }

    public var storage: Storage

    public static let identity = Self(.identity)
}

extension Rotation: Sendable {
}

public extension Rotation {
    var matrix: simd_float4x4 {
        switch storage {
        case .quaternion(let quaternion):
            return simd_float4x4(quaternion)
        case .rollPitchYaw(let rollPitchYaw):
            return rollPitchYaw.toMatrix4x4(order: .rollPitchYaw)
        }
    }
}

extension Rotation: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.quaternion == rhs.quaternion
    }
}

extension Rotation: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let vector = try container.decode(SIMD4<Float>.self)
        let quaternion = simd_quatf(vector: vector)
        self = .init(quaternion)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(quaternion.vector)
    }
}

public extension Rotation {
    init(_ quaternion: simd_quatf) {
        storage = .quaternion(quaternion)
    }

    init(_ rollPitchYaw: RollPitchYaw) {
        storage = .rollPitchYaw(rollPitchYaw)
    }
}

public extension Rotation {
    var quaternion: simd_quatf {
        get {
            switch storage {
            case .quaternion(let quaternion):
                return quaternion
            case .rollPitchYaw(let rollPitchYaw):
                return rollPitchYaw.toQuaternion(order: .rollPitchYaw)
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
                return RollPitchYaw(target: .object, quaternion: quaternion, order: .rollPitchYaw)
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
        self = .init(.init(angle: angle, axis: axis))
    }
}

public extension Rotation {
    func apply(_ p: SIMD3<Float>) -> SIMD3<Float> {
        (matrix * SIMD4<Float>(p, 1)).xyz
    }
}

public extension Rotation {
    func converted(to base: Rotation.Storage.Base) -> Rotation {
        switch base {
        case .quaternion:
            Rotation(quaternion)
        case .rollPitchYaw:
            Rotation(rollPitchYaw)
        }
    }
}

public extension Rotation.Storage {
    enum Base {
        case quaternion
        case rollPitchYaw
    }

    var base: Base {
        switch self {
        case .quaternion:
            .quaternion
        case .rollPitchYaw:
            .rollPitchYaw
        }
    }
}
