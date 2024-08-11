import Metal
import MetalKit
import MetalSupport
import ModelIO
import os
import RenderKitShaders
import Shapes2D
import SwiftUI

protocol MTLBufferProviding {
    var buffer: MTLBuffer { get }
}

extension YAMesh {
    // TODO: Maybe deprecate? @available(*, deprecated, message: "Move into converter api.")
    static func triangle(label: String? = nil, triangle: Triangle, transform: simd_float3x2 = simd_float3x2([1, 0], [0, 1], [0, 0]), device: MTLDevice, textureCoordinate: (CGPoint) -> SIMD2<Float>) throws -> YAMesh {
        let vertices = [
            triangle.vertices.0,
            triangle.vertices.1,
            triangle.vertices.2
        ]
        .map {
            // TODO; Normal not impacted by transform. It should be.
            SimpleVertex(position: SIMD2<Float>($0) * transform, normal: [0, 0, 1], textureCoordinate: textureCoordinate($0))
        }
        return try YAMesh.simpleMesh(label: label, indices: [0, 1, 2], vertices: vertices, device: device)
    }
}
