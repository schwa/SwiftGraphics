import MetalKit
import MetalSupport
import ModelIO
import SwiftUI

public struct Cone3D {
    public var center: SIMD3<Float> = .zero
    public var height: Float
    public var radius: Float

    public init(center: SIMD3<Float> = .zero, height: Float, radius: Float = 0.5) {
        self.center = center
        self.height = height
        self.radius = radius
    }
}

// MARK: -

extension Cone3D: MDLMeshConvertable {
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

        public func convert(_ cone: Cone3D) throws -> MDLMesh {
            assert(segments.count == 2)
            let mesh = MDLMesh(coneWithExtent: [cone.radius * 2, cone.height, cone.radius * 2], segments: .init(segments.map(UInt32.init)), inwardNormals: inwardNormals, cap: true, geometryType: geometryType, allocator: allocator)
            if flippedTextureCoordinates {
                mesh.flipTextureCoordinates(inAttributeNamed: "textureCoordinate")
            }
            return mesh
        }
    }
}
