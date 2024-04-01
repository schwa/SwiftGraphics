import simd

public extension simd_quatf {
    static var identity: simd_quatf {
        simd_quatf(real: 1, imag: .zero)
    }
}

public extension simd_quatf {
    init(_ quaternion: simd_quatd) {
        self = simd_quatf(real: Float(quaternion.real), imag: SIMD3<Float>(quaternion.imag))
    }
}

// MARK: -

public extension simd_quatd {
    static var identity: simd_quatd {
        simd_quatd(real: 1, imag: .zero)
    }
}

public extension simd_quatd {
    init(_ quaternion: simd_quatf) {
        self = simd_quatd(real: Double(quaternion.real), imag: SIMD3<Double>(quaternion.imag))
    }
}

extension simd_quatf {
    var innerDescription: String {
        "\(real.formatted()), [\(imag.x.formatted()), \(imag.y.formatted()), \(imag.z.formatted())]"
    }
}
