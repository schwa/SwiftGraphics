public protocol MeshConvertable {
    func toMesh() -> TrivialMesh<SIMD3<Float>>
}
