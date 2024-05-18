import simd


public struct Rotation: Equatable {
    public enum Storage: Equatable {
        case matrix(simd_float4x4)
        case quaternion(simd_quatf)
        case rollPitchYaw(RollPitchYaw)
    }

    public var storage: Storage
}

public extension Rotation {
    init(matrix: simd_float4x4) {
        storage = .matrix(matrix)
    }

    init(quaternion: simd_quatf) {
        storage = .quaternion(quaternion)
    }

    init(rollPitchYaw: RollPitchYaw) {
        storage = .rollPitchYaw(rollPitchYaw)
    }

    static func matrix(_ matrix: simd_float4x4) -> Self {
        .init(matrix: matrix)
    }

    static func quaternion(_ quaternion: simd_quatf) -> Self {
        .init(quaternion: quaternion)
    }

    static func rollPitchYaw(_ rollPitchYaw: RollPitchYaw) -> Self {
        .init(rollPitchYaw: rollPitchYaw)
    }
}

public extension Rotation {
    var matrix: simd_float4x4 {
        get {
            switch storage {
            case .matrix(let matrix):
                return matrix
            case .quaternion(let quaternion):
                return simd_float4x4(quaternion)
            case .rollPitchYaw(let rollPitchYaw):
                return rollPitchYaw.matrix
            }
        }
        set {
            storage = .matrix(newValue)
        }
    }

    var quaternion: simd_quatf {
        get {
            switch storage {
            case .matrix:
                fatalError("Unimplemented")
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
            case .matrix:
                fatalError("Unimplemented")
            case .quaternion:
                fatalError("Unimplemented")
            case .rollPitchYaw(let rollPitchYaw):
                return rollPitchYaw
            }
        }
        set {
            storage = .rollPitchYaw(newValue)
        }
    }
}
