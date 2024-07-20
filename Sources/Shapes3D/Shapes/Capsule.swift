import MetalKit
import MetalSupport
import ModelIO
import SwiftUI

public struct Capsule3D {
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

extension Capsule3D: MDLMeshConvertable {
    public struct MDLMeshConverter: MDLMeshConverterProtocol {
        public var segments: [Int]
        public var inwardNormals: Bool
        public var geometryType: MDLGeometryType
        public var flippedTextureCoordinates: Bool
        public var allocator: MDLMeshBufferAllocator?

        public init(allocator: MDLMeshBufferAllocator?) {
            segments = [8, 8, 8]
            inwardNormals = false
            geometryType = .triangles
            flippedTextureCoordinates = false
            self.allocator = allocator
        }

        public func convert(_ capsule: Capsule3D) throws -> MDLMesh {
            assert(segments.count == 3)
            let mesh = MDLMesh(capsuleWithExtent: [capsule.radius * 2, capsule.height, capsule.radius * 2], cylinderSegments: [UInt32(segments[0]), UInt32(segments[2])], hemisphereSegments: Int32(segments[1]), inwardNormals: inwardNormals, geometryType: geometryType, allocator: allocator)
            if flippedTextureCoordinates {
                mesh.flipTextureCoordinates(inAttributeNamed: "textureCoordinate")
            }
            return mesh
        }
    }
}
