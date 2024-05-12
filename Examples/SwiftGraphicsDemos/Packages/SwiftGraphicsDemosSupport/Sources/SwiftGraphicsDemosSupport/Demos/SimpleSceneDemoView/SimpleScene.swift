import CoreGraphicsSupport
import Metal
import MetalKit
import MetalSupport
import ModelIO
import RenderKit
import simd
import SIMDSupport
import SwiftUI

struct SimpleScene {
    var camera: Camera
    var light: Light
    var ambientLightColor: SIMD3<Float>
    var models: [Model]
    var panorama: Panorama?

    init(camera: Camera, light: Light, ambientLightColor: SIMD3<Float>, models: [Model], panorama: Panorama? = nil) {
        self.camera = camera
        self.light = light
        self.ambientLightColor = ambientLightColor
        self.models = models
        self.panorama = panorama
    }
}

// MARK: -

// struct Camera {
//    var transform: Transform
//    var target: SIMD3<Float> {
//        didSet {
//            let position = transform.translation // TODO: Scale?
//            transform = Transform(look(at: position + target, from: position, up: [0, 1, 0]))
//        }
//    }
//    var projection: Projection
//
//    init(transform: Transform, target: SIMD3<Float>, projection: Projection) {
//        self.transform = transform
//        self.target = target
//        self.projection = projection
//    }
// }
//
// extension Camera: Equatable {
// }
//
// extension Camera: Sendable {
// }
//
// extension Camera {
//    var heading: Angle {
//        get {
//            Angle(from: .zero, to: CGPoint(target.xz))
//        }
//        set {
//            target = SIMD3<Float>(xz: SIMD2<Float>(CGPoint(distance: Double(target.length), angle: newValue)))
//        }
//    }
// }

// MARK: -

struct Light {
    var position: Transform
    var color: SIMD3<Float>
    var power: Float
}

extension Light: Equatable {
}

extension Light: Sendable {
}

// MARK: -

struct Model: Identifiable {
    var id = LOLID2(prefix: "Model")
    var transform: Transform
    var material: any Material
    var mesh: YAMesh

    init(transform: Transform, material: any Material, mesh: YAMesh) {
        self.transform = transform
        self.material = material
        self.mesh = mesh
    }
}

struct Panorama: Identifiable {
    var id = LOLID2(prefix: "Model")
    var tilesSize: SIMD2<UInt16>
    var tileTextures: [(MTKTextureLoader) throws -> MTLTexture]
    var mesh: (MTLDevice) throws -> YAMesh

    init(tilesSize: SIMD2<UInt16>, tileTextures: [(MTKTextureLoader) throws -> MTLTexture], mesh: @escaping (MTLDevice) throws -> YAMesh) {
        assert(tileTextures.count == Int(tilesSize.x) * Int(tilesSize.y))
        self.tileTextures = tileTextures
        self.tilesSize = tilesSize
        self.mesh = mesh
    }
}

protocol Material: Labeled {
}

struct BlinnPhongMaterial: Material {
    var label: String?
    var baseColorFactor: SIMD4<Float> = .one
    var baseColorTexture: Texture?
}

// struct PBRMaterial: Material {
//    var label: String?
//    var baseColorFactor: SIMD4<Float> = .one
//    var baseColorTexture: Texture?
//    var metallicFactor: Float = 1.0
//    var roughnessFactor: Float = 1.0
//    var metallicRoughnessTexture: Texture?
//    var normalTexture: Texture?
//    var occlusionTexture: Texture?
// }

// struct CustomMaterial: Material {
//    var label: String?
//
//    var vertexShader: String
//    var fragmentShader: String
// }

struct Texture: Labeled {
    var label: String?
    var resource: any ResourceProtocol
    var options: TextureManager.Options

    init(label: String? = nil, resource: any ResourceProtocol, options: TextureManager.Options = .init()) {
        self.label = label
        self.resource = resource
        self.options = options
    }
}
