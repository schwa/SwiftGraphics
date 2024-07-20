import simd
import SwiftUI

/**
 A type to represent a 3d transformation as an `SRT` or a SIMD matrix.
 */
public struct Transform: Hashable {
    public enum Storage: Equatable {
        case matrix(simd_float4x4)
        case srt(SRT)
    }

    public private(set) var storage: Storage

    public static let identity = Self()

    public init(scale: SIMD3<Float> = .unit, rotation: Rotation = .identity, translation: SIMD3<Float> = .zero) {
        storage = .srt(SRT(scale: scale, rotation: rotation, translation: translation))
    }

    public init(_ matrix: simd_float4x4) {
        storage = .matrix(matrix)
    }

    public var matrix: simd_float4x4 {
        get {
            switch storage {
            case .matrix(let matrix):
                matrix
            case .srt(let srt):
                srt.matrix
            }
        }
        set {
            storage = .matrix(newValue)
        }
    }

    public init(_ srt: SRT) {
        storage = .srt(srt)
    }

    public var srt: SRT {
        get {
            switch storage {
            case .matrix(let matrix):
                let (scale, rotation, translation) = matrix.decompose
                return SRT(scale: scale, rotation: rotation, translation: translation)
            case .srt(let srt):
                return srt
            }
        }
        set {
            storage = .srt(newValue)
        }
    }

    public var scale: SIMD3<Float> {
        get {
            srt.scale
        }
        set {
            srt.scale = newValue
        }
    }

    public var rotation: Rotation {
        get {
            srt.rotation
        }
        set {
            srt.rotation = newValue
        }
    }

    public var translation: SIMD3<Float> {
        get {
            switch storage {
            case .matrix(let matrix):
                matrix.columns.3.xyz
            case .srt(let srt):
                srt.translation
            }
        }
        set {
            switch storage {
            case .matrix(let matrix):
                var matrix = matrix
                matrix.columns.3 = SIMD4(newValue, 1)
                self.matrix = matrix
            case .srt(let srt):
                var srt = srt
                srt.translation = newValue
                storage = .srt(srt)
            }
        }
    }

    // MARK: -
}

extension Transform: Sendable {
}

extension Transform.Storage: Sendable {
}

extension Transform.Storage: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .matrix(let matrix):
            matrix.altHash(into: &hasher)
        case .srt(let srt):
            srt.hash(into: &hasher)
        }
    }
}

public extension Transform {
    static func translation(_ translation: SIMD3<Float>) -> Transform {
        Transform(translation: translation)
    }
}

public extension Transform {
    func rotated(_ r: simd_quatf) -> Transform {
        var copy = self
        copy.rotation.quaternion *= r
        return copy
    }

    func rotated(angle: Angle, axis: SIMD3<Float>) -> Transform {
        rotated(simd_quatf(angle: angle, axis: axis))
    }
}

extension Transform: CustomStringConvertible {
    public var description: String {
        if self == .identity {
            return "Transform(.identity)"
        }
        switch storage {
        case .matrix(let matrix):
            return "Transform(\(matrix))"
        case .srt(let srt):
            return "Transform(\(srt.innerDescription))"
        }
    }
}

public extension Transform {
    init(scale: SIMD3<Float> = .unit, rotation: RollPitchYaw, translation: SIMD3<Float> = .zero) {
        storage = .srt(SRT(scale: scale, rotation: rotation, translation: translation))
    }
    init(scale: SIMD3<Float> = .unit, rotation: simd_quatf, translation: SIMD3<Float> = .zero) {
        storage = .srt(SRT(scale: scale, rotation: rotation, translation: translation))
    }
    init(scale: SIMD3<Float> = .unit, rotation: simd_float4x4, translation: SIMD3<Float> = .zero) {
        storage = .srt(SRT(scale: scale, rotation: rotation, translation: translation))
    }
}

public extension Transform {
    func scaled(_ scale: SIMD3<Float>) -> Transform {
        var copy = self
        copy.scale *= scale
        return copy
    }
}
