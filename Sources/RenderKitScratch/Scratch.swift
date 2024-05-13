import RenderKit
import RenderKitShaders
import simd
import SIMDSupport



extension Plane: CustomStringConvertible {
    public var description: String {
        return "Plane(normal: \(normal.x), \(normal.y), \(normal.z), w: \(w))"
    }
}
