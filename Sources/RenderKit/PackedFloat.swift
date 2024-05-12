import simd
import RenderKitShaders

public extension PackedFloat3 {
    init(_ value: SIMD3<Float>) {
        self = .init(x: value.x, y: value.y, z: value.z)
    }
}

extension PackedFloat3: Equatable {
    public static func == (lhs: PackedFloat3, rhs: PackedFloat3) -> Bool {
        SIMD3(lhs) == SIMD3(rhs)
    }
}

extension PackedFloat3: Hashable {
    public func hash(into hasher: inout Hasher) {
        SIMD3(self).hash(into: &hasher)
    }
}

extension PackedFloat3: @unchecked Sendable {
}

extension PackedFloat3: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Float...) {
        self = .init(x: elements[0], y: elements[1], z: elements[2])
    }
}

public extension SIMD3 where Scalar == Float {
    init(_ packed: PackedFloat3) {
        self = .init(x: packed.x, y: packed.y, z: packed.z)
    }
}
