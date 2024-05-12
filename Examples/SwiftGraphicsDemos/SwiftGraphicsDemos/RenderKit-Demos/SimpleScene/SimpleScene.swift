import Metal
import MetalSupport
import SIMDSupport
import simd
import ModelIO
import MetalKit
import SwiftUI
import RenderKit
import CoreGraphicsSupport

public struct SimpleScene {
    public var camera: Camera
    public var light: Light
    public var ambientLightColor: SIMD3<Float>
    public var models: [Model]
    public var panorama: Panorama?

    public init(camera: Camera, light: Light, ambientLightColor: SIMD3<Float>, models: [Model], panorama: Panorama? = nil) {
        self.camera = camera
        self.light = light
        self.ambientLightColor = ambientLightColor
        self.models = models
        self.panorama = panorama
    }
}

// MARK: -

public struct Camera {
    public var transform: Transform
    public var target: SIMD3<Float> {
        didSet {
            let position = transform.translation // TODO: Scale?
            transform = Transform(look(at: position + target, from: position, up: [0, 1, 0]))
        }
    }
    public var projection: Projection

    public init(transform: Transform, target: SIMD3<Float>, projection: Projection) {
        self.transform = transform
        self.target = target
        self.projection = projection
    }
}

extension Camera: Equatable {
}

extension Camera: Sendable {
}

public extension Camera {
    var heading: Angle {
        get {
            Angle(from: .zero, to: CGPoint(target.xz))
        }
        set {
            target = SIMD3<Float>(xz: SIMD2<Float>(CGPoint(distance: Double(target.length), angle: newValue)))
        }
    }
}

// MARK: -

public struct Light {
    public var position: Transform
    public var color: SIMD3<Float>
    public var power: Float

    public init(position: Transform, color: SIMD3<Float>, power: Float) {
        self.position = position
        self.color = color
        self.power = power
    }
}

extension Light: Equatable {
}

extension Light: Sendable {
}

// MARK: -

public struct Model: Identifiable {
    public var id = LOLID2(prefix: "Model")
    public var transform: Transform
    public var material: any Material
    public var mesh: YAMesh

    public init(transform: Transform, material: any Material, mesh: YAMesh) {
        self.transform = transform
        self.material = material
        self.mesh = mesh
    }
}

public struct Panorama: Identifiable {
    public var id = LOLID2(prefix: "Model")
    public var tilesSize: SIMD2<UInt16>
    public var tileTextures: [(MTKTextureLoader) throws -> MTLTexture]
    public var mesh: (MTLDevice) throws -> YAMesh

    init(tilesSize: SIMD2<UInt16>, tileTextures: [(MTKTextureLoader) throws -> MTLTexture], mesh: @escaping (MTLDevice) throws -> YAMesh) {
        assert(tileTextures.count == Int(tilesSize.x) * Int(tilesSize.y))
        self.tileTextures = tileTextures
        self.tilesSize = tilesSize
        self.mesh = mesh
    }
}

public protocol Material: Labeled {
}

public struct BlinnPhongMaterial: Material {
    public var label: String?
    public var baseColorFactor: SIMD4<Float> = .one
    public var baseColorTexture: Texture?
}

//struct PBRMaterial: Material {
//    var label: String?
//    var baseColorFactor: SIMD4<Float> = .one
//    var baseColorTexture: Texture?
//    var metallicFactor: Float = 1.0
//    var roughnessFactor: Float = 1.0
//    var metallicRoughnessTexture: Texture?
//    var normalTexture: Texture?
//    var occlusionTexture: Texture?
//}

//struct CustomMaterial: Material {
//    var label: String?
//
//    var vertexShader: String
//    var fragmentShader: String
//}

public struct Texture: Labeled {
    public var label: String?
    public var resource: any ResourceProtocol
    public var options: TextureManager.Options

    public init(label: String? = nil, resource: any ResourceProtocol, options: TextureManager.Options = .init()) {
        self.label = label
        self.resource = resource
        self.options = options
    }
}
