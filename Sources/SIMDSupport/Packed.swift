import simd

/// A vector of three floats where MemoryLoad.stride == 12 && MemoryLoad.size == 12
public struct PackedFloat3 {
    public var x: Float
    public var y: Float
    public var z: Float

    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public extension PackedFloat3 {
    subscript(_ index: Int) -> Float {
        get {
            switch index {
            case 0:
                return x
            case 1:
                return y
            case 2:
                return z
            default:
                fatalError("Index out of range")
            }
        }
        set {
            switch index {
            case 0:
                x = newValue
            case 1:
                y = newValue
            case 2:
                z = newValue
            default:
                fatalError("Index out of range")
            }
        }
    }
}

public extension PackedFloat3 {
    init(_ value: SIMD3<Float>) {
        self = .init(x: value.x, y: value.y, z: value.z)
    }
}

extension PackedFloat3: Equatable {
}

extension PackedFloat3: Hashable {
}

extension PackedFloat3: Sendable {
}

extension PackedFloat3: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Float...) {
        self = .init(x: elements[0], y: elements[1], z: elements[2])
    }
}

extension PackedFloat3: CustomDebugStringConvertible {
    public var debugDescription: String {
        "[\(x.formatted()), \(y.formatted()), \(z.formatted())]"
    }
}
public extension SIMD3 where Scalar == Float {
    init(_ packed: PackedFloat3) {
        self = .init(x: packed.x, y: packed.y, z: packed.z)
    }
}

// MARK: -

public struct PackedHalf3: Hashable, Sendable {
    public var x: Float16
    public var y: Float16
    public var z: Float16

    public init(x: Float16, y: Float16, z: Float16) {
        self.x = x
        self.y = y
        self.z = z
    }
}


public extension PackedHalf4 {
    init(_ other: SIMD4<Float>) {
        self = PackedHalf4(x: Float16(other.x), y: Float16(other.y), z: Float16(other.z), w: Float16(other.w))
    }
}

public typealias PackedHalf4 = simd_packed_half4

public extension SIMD3 where Scalar == Float {
    init(_ other: PackedHalf3) {
        self = SIMD3(Scalar(other.x), Scalar(other.y), Scalar(other.z))
    }
}

public extension PackedHalf3 {
    init(_ other: SIMD3<Float>) {
        self = PackedHalf3(x: Float16(other.x), y: Float16(other.y), z: Float16(other.z))
    }
}
