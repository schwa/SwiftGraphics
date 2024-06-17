import simd

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

extension PackedFloat3: @unchecked Sendable {
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
