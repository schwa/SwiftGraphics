import simd
import SwiftUI

extension simd_float4x4 {
    var translation: SIMD3<Float> {
        columns.3.xyz
    }
}

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        [x, y, z]
    }
}

extension GraphicsContext.Shading {
    static func color(_ rgb: SIMD3<Float>) -> Self {
        .color(Color(red: Double(rgb.x), green: Double(rgb.y), blue: Double(rgb.z)))
    }
}
