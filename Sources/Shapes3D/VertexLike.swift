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

//public struct SimpleVertex: VertexLike3 {
//    // Note: Order can be important when interacting with Metal APIs etc.
//    public var packedPosition: PackedFloat3
//    public var packedNormal: PackedFloat3
//    public var textureCoordinate: SIMD2<Float>
//}



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
