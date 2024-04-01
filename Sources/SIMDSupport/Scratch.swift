import simd

public extension SIMD3 where Scalar: Numeric {
    var volume: Scalar {
        x * y * z
    }
}

// TODO: Replace with SwiftNumerics?
public func cos<V>(_ v: V) -> V where V: BinaryFloatingPoint {
    V(cos(Double(v)))
}

// TODO: Replace with SwiftNumerics?
public func sin<V>(_ v: V) -> V where V: BinaryFloatingPoint {
    V(sin(Double(v)))
}

// TODO: Replace with SwiftNumerics?
public func atan2<F>(_ y: F, _ x: F) -> F where F: BinaryFloatingPoint {
    F(atan2(Double(y), Double(x)))
}

protocol AltHashable {
    func altHash(into hasher: inout Hasher)
}

extension AltHashable where Self: Hashable {
    func altHash(into hasher: inout Hasher) {
        hash(into: &hasher)
    }
}
