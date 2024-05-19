import MetalKit
import MetalSupport
import ModelIO
import SIMDSupport
import SwiftUI

public struct Sphere3D {
    public var center: SIMD3<Float>
    public var radius: Float

    public init(center: SIMD3<Float> = .zero, radius: Float = 0.5) {
        self.center = center
        self.radius = radius
    }
}

// MARK: -

extension Sphere3D: PolygonConvertable {
    public struct PolygonConverter: PolygonConverterProtocol {
        public init() {
        }
        public func convert(_ value: Sphere3D) throws -> [Polygon3D<SimpleVertex>] {
            return value.toPolygonsX()
        }
    }

    // TODO: Roll into convert()
    private func toPolygonsX() -> [Polygon3D<SimpleVertex>] {
        let slices = 12
        let stacks = 12
        var polygons: [Polygon3D<SimpleVertex>] = []
        func vertex(_ theta: Angle, _ phi: Angle) -> SimpleVertex {
            let dir = SIMD3<Float>(SIMD3<Double>(cos(theta.radians) * sin(phi.radians), cos(phi.radians), sin(theta.radians) * sin(phi.radians)))
            return SimpleVertex(position: dir * radius + center, normal: dir)
        }
        for i in 0 ..< slices {
            for j in 0 ..< stacks {
                let v1 = vertex(.degrees(Double(i) / Double(slices) * 360), .degrees(Double(j) / Double(stacks) * 180))
                let v2 = vertex(.degrees(Double(i + 1) / Double(slices) * 360), .degrees(Double(j) / Double(stacks) * 180))
                let v3 = vertex(.degrees(Double(i + 1) / Double(slices) * 360), .degrees(Double(j + 1) / Double(stacks) * 180))
                let v4 = vertex(.degrees(Double(i) / Double(slices) * 360), .degrees(Double(j + 1) / Double(stacks) * 180))
                polygons.append(Polygon3D(vertices: [v1, v2, v3]))
                polygons.append(Polygon3D(vertices: [v1, v3, v4]))
            }
        }
        return polygons
    }
}


// MARK: -

extension Sphere3D: MDLMeshConvertable {
    public struct MDLMeshConverter: MDLMeshConverterProtocol {
        public var segments: [Int]
        public var inwardNormals: Bool
        public var geometryType: MDLGeometryType
        public var flippedTextureCoordinates: Bool
        public var allocator: MDLMeshBufferAllocator?

        public init(allocator: MDLMeshBufferAllocator?) {
            segments = [36, 36]
            inwardNormals = false
            geometryType = .triangles
            flippedTextureCoordinates = false
            self.allocator = allocator
        }

        public init(segments: [Int] = [36, 36], inwardNormals: Bool = false, geometryType: MDLGeometryType = .triangles, flippedTextureCoordinates: Bool = false, allocator: MDLMeshBufferAllocator) {
            self.segments = segments
            self.inwardNormals = inwardNormals
            self.geometryType = geometryType
            self.flippedTextureCoordinates = flippedTextureCoordinates
            self.allocator = allocator
        }

        public func convert(_ sphere: Sphere3D) throws -> MDLMesh {
            assert(segments.count == 2)
            let mesh = MDLMesh(sphereWithExtent: [sphere.radius * 2, sphere.radius * 2, sphere.radius * 2], segments: SIMD2<UInt32>(segments.map { UInt32($0) }), inwardNormals: inwardNormals, geometryType: .triangles, allocator: allocator)
            if flippedTextureCoordinates {
                mesh.flipTextureCoordinates(inAttributeNamed: "textureCoordinate")
            }
            return mesh
        }
    }
}
