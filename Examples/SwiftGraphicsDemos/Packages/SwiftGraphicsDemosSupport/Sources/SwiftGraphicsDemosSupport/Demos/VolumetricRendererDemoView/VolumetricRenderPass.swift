import Everything
import Metal
import MetalKit
import MetalSupport
import ModelIO
import os
import RenderKit
import RenderKitShaders
import Shapes2D
import SIMDSupport
import SwiftUI

class VolumetricRenderPass: RenderPass {
    let id = LOLID2(prefix: "VolumeRenderPass")
    var scene: SimpleScene?
    var renderPipelineState: MTLRenderPipelineState?
    var depthStencilState: MTLDepthStencilState?
    var texture: MTLTexture
    var cache = Cache<String, Any>()
    var rotation: Rotation = .zero
    var transferFunctionTexture: MTLTexture
    var logger: Logger?

    init() throws {
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

    func setup(device: MTLDevice, configuration: inout some MetalConfiguration) throws {
        if renderPipelineState == nil {
            let library = try! device.makeDebugLibrary(bundle: .shadersBundle)
            let vertexFunction = library.makeFunction(name: "volumeVertexShader")!
            let fragmentFunction = library.makeFunction(name: "volumeFragmentShader")

            let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
            renderPipelineDescriptor.vertexFunction = vertexFunction
            renderPipelineDescriptor.fragmentFunction = fragmentFunction
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat
            renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
            renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
            renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

            renderPipelineDescriptor.depthAttachmentPixelFormat = configuration.depthStencilPixelFormat
            let descriptor = VertexDescriptor.packed(semantics: [.position, .normal, .textureCoordinate])
            renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(descriptor)

            renderPipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }

        if depthStencilState == nil {
            let depthStencilDescriptor = MTLDepthStencilDescriptor()
            depthStencilDescriptor.depthCompareFunction = .lessEqual
            depthStencilDescriptor.isDepthWriteEnabled = true
            depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        }
    }

    func draw(device: MTLDevice, size: CGSize, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) throws {
        do {
            guard let renderPipelineState, let depthStencilState else {
                return
            }
            try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor) { encoder in
                encoder.setRenderPipelineState(renderPipelineState)
                encoder.setDepthStencilState(depthStencilState)

                let camera = Camera(transform: .init(translation: [0, 0, 2]), target: .zero, projection: .perspective(PerspectiveProjection(fovy: .degrees(90), zClip: 0.01 ... 10)))

                let modelTransform = Transform(scale: [2, 2, 2], rotation: rotation.quaternion)

                let mesh2 = try cache.get(key: "mesh2", of: YAMesh.self) {
                    let rect = CGRect(center: .zero, radius: 0.5)
                    let circle = Shapes2D.Circle(containing: rect)
                    let triangle = Triangle(containing: circle)
                    return try YAMesh.triangle(label: "triangle", triangle: triangle, device: device) {
                        SIMD2<Float>($0) + [0.5, 0.5]
                    }
//                    return try SimpleMesh(label: "rectangle", rectangle: rect, device: configuration.device!) {
//                        SIMD2<Float>($0) + [0.5, 0.5]
//                    }
                }
                encoder.setVertexBuffers(mesh2)

                // Vertex Buffer Index 1
                let cameraUniforms = CameraUniforms(projectionMatrix: camera.projection.matrix(viewSize: SIMD2<Float>(size)))
                encoder.setVertexBytes(of: cameraUniforms, index: 1)

                // Vertex Buffer Index 2
                let modelUniforms = VolumeTransforms(
                    modelViewMatrix: camera.transform.matrix.inverse * modelTransform.matrix,
                    textureMatrix: simd_float4x4(translate: [0.5, 0.5, 0.5]) * rotation.matrix * simd_float4x4(translate: [-0.5, -0.5, -0.5])
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
        catch {
            logger?.error("Render error: \(error)")
        }
    }
}

extension VolumetricRenderPass: Observable {
}
