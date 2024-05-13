import simd
import SIMDSupport
import MetalSupport

public protocol VertexLike: Equatable {
    associatedtype Vector: PointLike

    var position: Vector { get set }
}

public protocol VertexLike3: VertexLike where Vector: PointLike3 {
    var normal: Vector { get set }
}

extension SIMD3<Float>: VertexLike {
    public var position: SIMD3<Float> {
        get {
            self
        }
        set {
            self = newValue
        }
    }
}

extension SimpleVertex: VertexLike3 {
}
