import simd
import SwiftUI

public extension simd_quatf {
    static var identity: simd_quatf {
        simd_quatf(real: 1, imag: .zero)
    }

    init(angle: Angle, axis: SIMD3<Float>) {
        self = simd_quatf(angle: Float(angle.radians), axis: axis)
    }

    init(_ quaternion: simd_quatd) {
        self = simd_quatf(real: Float(quaternion.real), imag: SIMD3<Float>(quaternion.imag))
    }
}

extension simd_quatf {
    var innerDescription: String {
        "\(real.formatted()), [\(imag.x.formatted()), \(imag.y.formatted()), \(imag.z.formatted())]"
    }
}

// MARK: -

public extension simd_quatd {
    static var identity: simd_quatd {
        simd_quatd(real: 1, imag: .zero)
    }

    init(angle: Angle, axis: SIMD3<Double>) {
        self = simd_quatd(angle: angle.radians, axis: axis)
    }

    init(_ quaternion: simd_quatf) {
        self = simd_quatd(real: Double(quaternion.real), imag: SIMD3<Double>(quaternion.imag))
    }
}
