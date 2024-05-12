import RenderKit
import RenderKitShaders
import simd
import SIMDSupport

extension SIMD3 where Scalar == Float {
    func dot(_ other: Self) -> Float {
        simd_dot(self, other)
    }
}

extension SimpleVertex {
    init(position: SIMD3<Float>, normal: SIMD3<Float>) {
        self.init(position: position, normal: normal, textureCoordinate: .zero)
    }
}

extension Plane: CustomStringConvertible {
    public var description: String {
        return "Plane(normal: \(normal.x), \(normal.y), \(normal.z), w: \(w))"
    }
}
