import simd

extension SIMD2: AltHashable where Scalar: Hashable {
    public func altHash(into hasher: inout Hasher) {
        scalars.hash(into: &hasher)
    }
}

extension SIMD3: AltHashable where Scalar: Hashable {
    public func altHash(into hasher: inout Hasher) {
        scalars.hash(into: &hasher)
    }
}

extension SIMD4: AltHashable where Scalar: Hashable {
    public func altHash(into hasher: inout Hasher) {
        scalars.hash(into: &hasher)
    }
}

extension simd_quatf: AltHashable {
    public func altHash(into hasher: inout Hasher) {
        vector.altHash(into: &hasher)
    }
}

extension simd_quatd: AltHashable {
    public func altHash(into hasher: inout Hasher) {
        vector.altHash(into: &hasher)
    }
}

extension simd_float4x4: AltHashable {
    public func altHash(into hasher: inout Hasher) {
        scalars.hash(into: &hasher)
    }
}
