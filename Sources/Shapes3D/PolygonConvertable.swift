import MetalSupport
import SwiftGraphicsSupport
import ModelIO
import Metal
import MetalKit

public protocol PolygonConverterProtocol: ConverterProtocol {
    associatedtype Input

    init()
    func convert(_ value: Input) throws -> [Polygon3D<SimpleVertex>]
}

public protocol PolygonConvertable {
    associatedtype PolygonConverter: PolygonConverterProtocol where PolygonConverter.Input == Self
}

public extension PolygonConvertable {
    func toPolygons() throws -> [Polygon3D<SimpleVertex>] {
        let converter = PolygonConverter()
        return try converter.convert(self)
    }
}

// MARK: -

public protocol TrianglesConverterProtocol: ConverterProtocol {
    init()
}


public protocol TrianglesConvertable {
    associatedtype Vertex: VertexLike
    associatedtype TrianglesConverter: TrianglesConverterProtocol where TrianglesConverter.Input == Self, TrianglesConverter.Output == [Triangle3D<Vertex>]
}

extension TrianglesConvertable {
    func toTriangles() throws -> [Triangle3D<Vertex>] {
        let converter = TrianglesConverter()
        return try converter.convert(self)
    }
}

extension Quad: TrianglesConvertable {

    public struct TrianglesConverter: TrianglesConverterProtocol {
        public init() {
        }

        public func convert(_ value: Quad) throws -> [Triangle3D<Vertex>] {
            let triangles = value.subdivide()
            return [triangles.0, triangles.1]
        }
    }
}

public extension TrianglesConvertable where Vertex == SimpleVertex {
    func toTrivialMesh() throws -> TrivialMesh<Vertex> {
        let triangles = try toTriangles()
        return TrivialMesh(triangles: triangles)
    }

    func toMDLMesh(allocator: MDLMeshBufferAllocator? = nil) throws -> MDLMesh {
        let trivialMesh = try toTrivialMesh()
        return try MDLMesh(trivialMesh: trivialMesh, allocator: allocator)
    }

    func toMTKMesh(device: MTLDevice) throws -> MTKMesh {
        let allocator = MTKMeshBufferAllocator(device: device)
        let mdlMesh = try toMDLMesh(allocator: allocator)
        return try MTKMesh(mesh: mdlMesh, device: device)
    }
}

public extension Triangle3D {
    func map<VertexOut>(_ transform: (Vertex) -> VertexOut) -> Triangle3D<VertexOut> where VertexOut: VertexLike {
        return Triangle3D<VertexOut>(vertices: (transform(vertices.0), transform(vertices.1), transform(vertices.2)))
    }
}

public extension Triangle3D where Vertex == SIMD3<Float> {
    func convert() -> Triangle3D<SimpleVertex> {
        let normal = simd_normalize(simd_cross(vertices.1 - vertices.0, vertices.2 - vertices.0))
        return map { vertex in
            SimpleVertex(position: vertex, normal: normal, textureCoordinate: .zero)
        }
    }
}
