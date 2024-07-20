import MetalKit
import MetalSupport
import ModelIO
import SwiftUI

public struct Cylinder3D {
    public var radius: Float
    public var height: Float
    public var topCap: Bool
    public var bottomCap: Bool

    public init(radius: Float, height: Float, topCap: Bool = true, bottomCap: Bool = true) {
        self.radius = radius
        self.height = height
        self.topCap = topCap
        self.bottomCap = bottomCap
    }
}

extension Cylinder3D: MDLMeshConvertable {
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

        public func convert(_ shape: Cylinder3D) throws -> MDLMesh {
            assert(segments.count == 2)

            let extent: SIMD3<Float> = [shape.radius * 2, shape.height, shape.radius * 2]
            let segments: SIMD2<UInt32> = [UInt32(segments[0]), UInt32(segments[1])]

            let mesh = MDLMesh(cylinderWithExtent: extent, segments: segments, inwardNormals: inwardNormals, topCap: shape.topCap, bottomCap: shape.bottomCap, geometryType: geometryType, allocator: allocator)
            if flippedTextureCoordinates {
                mesh.flipTextureCoordinates(inAttributeNamed: "textureCoordinate")
            }
            return mesh
        }
    }
}
