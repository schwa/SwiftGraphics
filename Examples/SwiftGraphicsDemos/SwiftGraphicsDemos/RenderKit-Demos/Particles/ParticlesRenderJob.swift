import SwiftUI
import ModelIO
import Metal
import MetalKit
import SIMDSupport
import RenderKitShaders
import RenderKit
import Observation
import Everything
import SwiftFormats

class ParticlesRenderJob: RenderJob {
    var renderPipelineState: MTLRenderPipelineState?
    var depthStencilState: MTLDepthStencilState?
    var mesh: YAMesh?
    var positions: MTLBuffer?
    var velocities: MTLBuffer?
    var densities: MTLBuffer?
    var colors: [Float] = []
    var simulation: Simulation<UnsafeBufferSimulationStorage>?

    func setup<Configuration: MetalConfiguration>(device: MTLDevice, configuration: inout Configuration) throws {
        let count = 500

        positions = device.makeBuffer(length: count * MemoryLayout<SIMD2<Float>>.stride, options: .storageModeShared)!.labelled("positions")
        velocities = device.makeBuffer(length: count * MemoryLayout<SIMD2<Float>>.stride, options: .storageModeShared)!.labelled("velocities")
        densities = device.makeBuffer(length: count * MemoryLayout<Float>.stride, options: .storageModeShared)!.labelled("densities")

        simulation = Simulation(
            count: count,
            storage: UnsafeBufferSimulationStorage(
                positions: positions!.contentsBuffer(of: SIMD2<Float>.self),
                velocities: velocities!.contentsBuffer(of: SIMD2<Float>.self),
                densities: densities!.contentsBuffer(of: Float.self)
            ),
            size: [1000, 1000]
        )

        let library = try! device.makeDefaultLibrary(bundle: .shadersBundle)
        let vertexFunction = library.makeFunction(name: "particleVertexShader")!
        let constantValues = MTLFunctionConstantValues()
        let fragmentFunction = try library.makeFunction(name: "particleFragmentShader", constantValues: constantValues)

        depthStencilState = device.makeDepthStencilState(descriptor: MTLDepthStencilDescriptor.always())
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat
        renderPipelineDescriptor.colorAttachments[0].enableStandardAlphaBlending()
        renderPipelineDescriptor.depthAttachmentPixelFormat = configuration.depthStencilPixelFormat
        renderPipelineDescriptor.label = "\(self)"
        let descriptor = VertexDescriptor.packed(semantics: [.position, .normal, .textureCoordinate])
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(descriptor)
        renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)

        mesh = try YAMesh.plane(label: "plane", rectangle: [-0.5, -0.5, 1, 1], device: device) { .init($0) + [0.5, 0.5] }
    }

    func encode(on encoder: MTLRenderCommandEncoder, size: CGSize) throws {
        guard let renderPipelineState, let depthStencilState, let mesh else {
            return
        }
        encoder.withDebugGroup("Particles") {
            encoder.setRenderPipelineState(renderPipelineState)
            encoder.setDepthStencilState(depthStencilState)
            encoder.setVertexBuffers(mesh)
            let size = SIMD2<Float>(size)
            var view = simd_float4x4.identity
            view *= simd_float4x4.scaled([1 / size.x * 2, 1 / size.y * 2, 1])
            view *= simd_float4x4.translation([-size.x / 2, -size.y / 2, 0])
            let cameraUniforms = CameraUniforms(projectionMatrix: view)
            encoder.setVertexBytes(of: cameraUniforms, index: 1)
            encoder.setVertexBuffer(self.positions, offset: 0, index: 2)
            encoder.setTriangleFillMode(.fill)
            encoder.draw(mesh, instanceCount: simulation!.count)
        }

        simulation?.size = size
        simulation?.step(time: CFAbsoluteTimeGetCurrent())
    }
}
