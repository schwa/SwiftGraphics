import Everything
import Metal
import MetalKit
import MetalSupport
import MetalUISupport
import ModelIO
import os
import RenderKit
import RenderKitShadersLegacy
import Shapes2D
import SIMDSupport
import SwiftGraphicsSupport
import SwiftUI

struct VolumetricRenderPass: RenderPassProtocol {
    let id: AnyHashable = "VolumetricRenderPass"
    var cache = Cache<String, Any>()
    var rollPitchYaw: RollPitchYaw = .zero
    var transferFunctionTexture: MTLTexture
    var logger: Logger?
    var texture: MTLTexture

    // TODO: WORKAROUND
    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.rollPitchYaw == rhs.rollPitchYaw
    }

    struct State: PassState {
        var renderPipelineState: MTLRenderPipelineState
        var depthStencilState: MTLDepthStencilState
    }

    init() throws {
        print(#function)
        let device = MTLCreateSystemDefaultDevice()! // TODO: Naughty
        let volumeData = try! VolumeData(named: "CThead", in: Bundle.module, size: [256, 256, 113]) // TODO: Hardcoded
        //        let volumeData = VolumeData(named: "MRBrain", size: [256, 256, 109])
        let load = try! volumeData.load()
        texture = try! load(device)

        // TODO: Hardcoded
        let textureDescriptor = MTLTextureDescriptor()
        // We actually only need this texture to be 1D but Metal doesn't allow buffer backed 1D textures which seems assinine. Maybe we don't need it to be buffer backed and just need to call texture.copy each update?
        textureDescriptor.textureType = .type1D
        textureDescriptor.width = 256 // TODO: Hardcoded
        textureDescriptor.height = 1
        textureDescriptor.depth = 1
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.storageMode = .shared
        let texture = try device.makeTexture(descriptor: textureDescriptor).safelyUnwrap(GeneralError.generic("Could not create texture"))
        texture.label = "transfer function"
        transferFunctionTexture = texture
    }

    func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .renderKitShadersLegacy)
        let vertexFunction = library.makeFunction(name: "volumeVertexShader")!
        let fragmentFunction = library.makeFunction(name: "volumeFragmentShader")

        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        let descriptor = VertexDescriptor.packed(semantics: [.position, .normal, .textureCoordinate])
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(descriptor)

        let renderPipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)

        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilDescriptor.isDepthWriteEnabled = true
        let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
        return .init(renderPipelineState: renderPipelineState, depthStencilState: depthStencilState)
    }

    func encode(device: MTLDevice, state: inout State, drawableSize: SIMD2<Float>, commandEncoder encoder: MTLRenderCommandEncoder) throws {
        encoder.setRenderPipelineState(state.renderPipelineState)
        encoder.setDepthStencilState(state.depthStencilState)

        let cameraProjection: Projection = .perspective(PerspectiveProjection(verticalAngleOfView: .degrees(90), zClip: 0.01 ... 10))
        let cameraTransform: Transform = .init(translation: [0, 0, 2])

        let modelTransform = Transform(scale: [2, 2, 2], rotation: .rollPitchYaw(rollPitchYaw))

        let mesh2 = try cache.get(key: "mesh2", of: YAMesh.self) {
            let rect = CGRect(center: .zero, radius: 0.5)
            let circle = Shapes2D.Circle(containing: rect)
            let triangle = Triangle(containing: circle)
            return try YAMesh.triangle(label: "triangle", triangle: triangle, device: device) {
                SIMD2<Float>($0) + [0.5, 0.5]
            }
        }
        encoder.setVertexBuffers(mesh2)

        // Vertex Buffer Index 1
        let cameraUniforms = CameraUniforms(projectionMatrix: cameraProjection.projectionMatrix(for: drawableSize))
        encoder.setVertexBytes(of: cameraUniforms, index: 1)

        // Vertex Buffer Index 2
        let modelUniforms = VolumeTransforms(
            modelViewMatrix: cameraTransform.matrix.inverse * modelTransform.matrix,
            textureMatrix: simd_float4x4(translate: [0.5, 0.5, 0.5]) * rollPitchYaw.matrix4x4 * simd_float4x4(translate: [-0.5, -0.5, -0.5])
        )
        encoder.setVertexBytes(of: modelUniforms, index: 2)

        // Vertex Buffer Index 3

        let instanceCount = 256 // TODO: Random - numbers as low as 32 - but you will see layering in the image.

        let instances = cache.get(key: "instance_data", of: MTLBuffer.self) {
            let instances = (0 ..< instanceCount).map { slice in
                let z = Float(slice) / Float(instanceCount - 1)
                return VolumeInstance(offsetZ: z - 0.5, textureZ: 1 - z)
            }
            let buffer = device.makeBuffer(bytesOf: instances, options: .storageModeShared)!
            buffer.label = "instances"
            assert(buffer.length == 8 * instanceCount)
            return buffer
        }
        encoder.setVertexBuffer(instances, offset: 0, index: 3)

        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentTexture(transferFunctionTexture, index: 1)

        // TODO: Hard coded
        let fragmentUniforms = VolumeFragmentUniforms(instanceCount: UInt16(instanceCount), maxValue: 3_272, alpha: 10.0)
        encoder.setFragmentBytes(of: fragmentUniforms, index: 0)

        encoder.draw(mesh2, instanceCount: instanceCount)
    }
}

extension VolumetricRenderPass: Observable {
}
